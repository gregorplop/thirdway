#tag Class
Protected Class thirdwayController
	#tag Method, Flags = &h0
		Function AddWorker() As Integer
		  // output is new worker index or -1 for failure. error message in LastError
		  
		  dim newSession as new PostgreSQLDatabase
		  
		  newSession.Host = pgSession.Host
		  newSession.Port = pgSession.Port
		  newSession.DatabaseName = pgSession.DatabaseName
		  newSession.UserName = pgSession.UserName
		  newSession.Password = pgSession.Password
		  newSession.AppName = "thirdwayWorker_" + str(WorkerPool.Ubound + 1)
		  
		  WorkerPool.Append new thirdwayControllerWorker(newSession)
		  
		  dim NewWorkerIDX as Integer = WorkerPool.Ubound
		  
		  if WorkerPool(NewWorkerIDX).LastError = "" then  // worker initialized ok
		    AddHandler WorkerPool(NewWorkerIDX).Respond , WeakAddressOf responseSender  // use the thirdwayController pgSession for sending responses
		  else  // error initializing new worker, remove it from pool
		    WorkerPool.Remove(NewWorkerIDX)
		    NewWorkerIDX = -1
		  end if
		  
		  Return NewWorkerIDX
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function AvailableWorker() As integer
		  for i as Integer = 0 to WorkerPool.Ubound
		    
		    if WorkerPool(i).isBusy = false then return i
		    
		  next i
		  
		  Return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(byref initSession as PostgreSQLDatabase)
		  if IsNull(initSession) then
		    mLastError = "No valid postgres session"
		    return
		  end if
		  
		  pgSession = initSession
		  mCurrentPID = getPID 
		  if mCurrentPID = -1 then 
		    mLastError = "Error getting PID"
		    return
		  end if
		  
		  
		  dim LimnieValid as String = verifyLimnie
		  if LimnieValid <> "" then 
		    mLastError = LimnieValid
		    Return
		  end if
		  
		  
		  pgSession.SQLExecute("LISTEN thirdway_controller")
		  if pgSession.Error then
		    mLastError = "Error initiating listening"
		    Return
		  end if
		  
		  // just an example of declaring requests this session (thirdway controller) will have to process
		  RequestDeclarations.Append new pgReQ_request("ACKNOWLEDGE" , 120 , true)
		  RequestDeclarations.Append new pgReQ_request("PUSH" , 120 , true) 
		  RequestDeclarations.Append new pgReQ_request("PULL" , 120 , true) 
		  
		  
		  
		  AddHandler pgSession.ReceivedNotification , WeakAddressOf pgSessionReceiveNotification
		  
		  queuePollTimer = new Timer
		  queuePollTimer.Period = PollTimerPeriod
		  AddHandler queuePollTimer.Action , WeakAddressOf PollTimerAction
		  queuePollTimer.Mode = timer.ModeMultiple
		  
		  mLastError = ""
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function getPID() As integer
		  if IsNull(pgSession) then return -1
		  
		  dim rs as RecordSet = pgSession.SQLSelect("SELECT pg_backend_pid()")
		  
		  if pgSession.Error then 
		    return -1
		  else
		    Return rs.IdxField(1).IntegerValue
		  end if
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function getRequestReceived(UUID as string) As pgReQ_request
		  dim idx as Integer = getRequestReceivedIDX(UUID)
		  if idx < 0 then Return new pgReQ_request(true , "Request not found in received queue!")
		  Return RequestsReceived(idx).Clone
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function getRequestReceivedIDX(UUID as string) As Integer
		  dim i as Integer = 0
		  
		  while i <= RequestsReceived.Ubound
		    if RequestsReceived(i).UUID = UUID then Return i
		    i = i + 1
		  wend
		  
		  return -1
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function getUUID() As string
		  if IsNull(pgSession) then return ""
		  
		  dim rs as RecordSet = pgSession.SQLSelect("SELECT uuid_in(md5(random()::text || clock_timestamp()::text)::cstring)")
		  
		  if pgSession.Error then 
		    Return ""
		  else
		    Return rs.IdxField(1).StringValue
		  end if
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function isUUID(candidate as string) As Boolean
		  if candidate.len <> 36 then return false
		  if candidate.CountFields("-") <> 5 then return false
		  
		  // this is just a very superficial way to validate a uuid
		  
		  return true
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As string
		  return mLastError
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub pgSessionReceiveNotification(sender as PostgreSQLDatabase, Name as string, ID as integer, Extra as String)
		  // name = channel coming from - ID = pid of the sender - extra = the json-formatted request
		  
		  dim incomingRequest as new pgReQ_request(extra)
		  
		  if incomingRequest.Error then return// not a pgReQ request
		  
		  
		  // it's pgReQ
		  
		  if ID = mCurrentPID then return  // it's a message this session sent out and for some reason it's set up to listen to that channel
		  
		  // is it a response to a request I've made?
		  if incomingRequest.isResponse and incomingRequest.initiatorPID = mCurrentPID then
		    dim idx as Integer = searchAwaitingRequestsQueue(incomingRequest.UUID)
		    if idx < 0 then // we've made this request but we are no longer waiting for the Response
		      // probably response expired here but handler processed and sent it before it expired there too
		      // we'll just ignore it
		    else  // we got a reply we've been waiting for
		      RequestsAwaitingResponse.Remove(idx)
		      ResponsesReceived.Append incomingRequest
		      
		      ResponseReceived(incomingRequest.UUID)  // used to be an event
		      
		    end if
		    Return
		  end if
		  
		  
		  // is it a request I'm configured to process?
		  for i as Integer = 0 to RequestDeclarations.Ubound
		    if RequestDeclarations(i).Type.Uppercase = incomingRequest.Type.Uppercase then //yes
		      incomingRequest.processing = false
		      incomingRequest.MyOwnRequest = false
		      RequestsReceived.Append incomingRequest
		      
		      RequestReceived(incomingRequest.UUID)  // used to be an event
		      
		      return
		    end if
		  next i
		  
		  // cannot think of anything else...
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PID() As Integer
		  Return mCurrentPID
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub PollTimerAction(sender as Timer)
		  if IsNull(pgSession) then  // there's no connection to the db
		    sender.Mode = timer.ModeOff
		    RaiseEvent ServiceInterrupted("Connection to postgres server no longer valid")
		    return
		  end if
		  
		  
		  VerifyServiceCounter = VerifyServiceCounter + 1
		  dim thisSecond as Int64 = date(new date).TotalSeconds
		  
		  if lastSecond <> thisSecond then  // code here executes once per second
		    lastSecond = thisSecond
		    dim expiredRequest as pgReQ_request
		    dim i as Integer
		    
		    // we allow one expiration per second --this is an intentional design decision, we might revise
		    
		    expiredRequest = nil
		    i = 0
		    while i <= RequestsAwaitingResponse.Ubound
		      RequestsAwaitingResponse(i).TimeoutCountdown = RequestsAwaitingResponse(i).TimeoutCountdown - 1
		      if RequestsAwaitingResponse(i).TimeoutCountdown < 0 then  // this request has expired
		        expiredRequest = RequestsAwaitingResponse(i).Clone
		        RequestsAwaitingResponse.Remove(i)
		        exit while
		      end if
		      i = i + 1
		    wend
		    
		    if IsNull(expiredRequest) = false then 
		      RequestExpired(expiredRequest)  // used to be an event
		      
		    else
		      i = 0
		      while i <= RequestsReceived.Ubound
		        RequestsReceived(i).TimeoutCountdown = RequestsReceived(i).TimeoutCountdown - 1
		        if RequestsReceived(i).TimeoutCountdown < 0 then  // this request has expired
		          expiredRequest = RequestsReceived(i).Clone
		          RequestsReceived.Remove(i)
		          exit while
		        end if
		        i = i + 1
		      wend
		      if IsNull(expiredRequest) = false then RequestExpired(expiredRequest)  // used to be an event
		    end if
		    
		    
		  end if
		  
		  
		  if VerifyServiceCounter > VerifyServiceIntervalMultiplier then  // code here executes once per VerifyServiceIntervalMultiplier
		    
		    dim currentPID as Integer = getPID 
		    
		    if mCurrentPID <> currentPID then // db error/disconnect/reconnect
		      sender.Mode = timer.ModeOff
		      RaiseEvent ServiceInterrupted("Error verifying current PID")
		      Return
		    end if
		    
		    VerifyServiceCounter = 0
		    
		  end if
		  
		  // code below executes once per PollTimerPeriod
		  
		  pgSession.CheckForNotifications
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function popResponse(UUID as string) As pgReQ_request
		  // returns a handled request from the ResponsesReceived queue and removes it from there
		  
		  dim i as Integer = 0
		  dim output as pgReQ_request = nil
		  
		  while i <= ResponsesReceived.Ubound
		    if ResponsesReceived(i).UUID = UUID then 
		      output = ResponsesReceived(i).Clone
		      ResponsesReceived.Remove(i)
		      Return output
		    end if
		    i = i + 1
		  wend
		  
		  return output  // nil that is
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub RequestExpired(ExpiredRequest as pgReQ_request)
		  select case ExpiredRequest.Type
		    
		  case "PUSH"
		    
		  end select
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub RequestReceived(UUID as String)
		  dim thisJustIn as pgReQ_request = getRequestReceived(UUID)
		  
		  if thisJustIn.Error then Return
		  
		  select case thisJustIn.Type
		    
		  case "PUSH"
		    
		    RaiseEvent WriteLog("PUSH rq received: " + thisJustIn.UUID) // in-app logging
		    
		    dim freeWorkerIDX as Integer = AvailableWorker
		    
		    if freeWorkerIDX < 0 then // no free worker
		      
		      dim newWorkerIDX as Integer = AddWorker
		      
		      if newWorkerIDX >= 0 then // new worker created ok, put it to work
		        WorkerPool(newWorkerIDX).ProcessRequest(thisJustIn)
		      else  // error starting new worker -- fail the request AND don't care about the response being successfully sent
		        call sendResponse(thisJustIn.UUID , new Dictionary("thirdway_errormsg" : "Controller could not start worker"))
		      end if
		      
		    else  // use an existing, free worker
		      WorkerPool(freeWorkerIDX).ProcessRequest(thisJustIn)
		    end if
		    
		  end select
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub ResponseReceived(UUID as String)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub responseSender(sender as thirdwayControllerWorker, UUID as string, response as Dictionary)
		  dim sendOutcome as pgReQ_request =  sendResponse(UUID , response)
		  
		  if sendOutcome.Error then
		    System.DebugLog("Controller failed to respond to " + UUID + " : " + sendOutcome.ErrorMessage)
		  end if
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function rollbackPush(UUID as string) As Boolean
		  dim clearDocError , clearCacheError as Boolean
		  
		  pgSession.SQLExecute("DELETE FROM thirdway.repository WHERE docid = '" + UUID + "'")
		  clearDocError = pgSession.Error
		  
		  pgSession.SQLExecute("DELETE FROM thirdway.cache WHERE docid = '" + UUID + "'")
		  clearCacheError = pgSession.Error
		  
		  if clearDocError or clearCacheError then
		    return false
		  else
		    return true
		  end if
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function searchAwaitingRequestsQueue(UUID as String) As Integer
		  dim i as Integer = 0
		  
		  while i <= RequestsAwaitingResponse.Ubound
		    if RequestsAwaitingResponse(i).UUID = UUID then return i
		    i = i + 1
		  wend
		  
		  return -1
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function sendRequest(request2send as pgReQ_request) As pgReQ_request
		  if request2send.Error then Return request2send
		  
		  if IsNull(pgSession) then 
		    request2send.Error = true
		    request2send.ErrorMessage = "No PostgreSQL session!"
		    Return request2send
		  end if
		  
		  
		  if isUUID(request2send.UUID) = false then
		    request2send.UUID = getUUID
		    
		    if request2send.UUID = "" then
		      request2send.Error = true
		      request2send.ErrorMessage = "Could not get UUID!"
		      Return request2send
		    end if
		  end if
		  
		  request2send.creationStamp = new Date
		  request2send.initiatorPID = mCurrentPID
		  request2send.MyOwnRequest = true
		  
		  dim JSONpackage as String = request2send.toJSON
		  
		  dim NOTIFY as string = "NOTIFY " + request2send.RequestChannel + " , '" + JSONpackage + "'"
		  pgSession.SQLExecute(NOTIFY)
		  
		  if pgSession.Error then
		    request2send.Error = true
		    request2send.ErrorMessage = "Error sending request: " + pgSession.ErrorMessage
		    Return request2send
		  end if
		  
		  if request2send.RequireResponse then RequestsAwaitingResponse.Append request2send.Clone
		  
		  Return request2send
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function sendResponse(UUID as string, response as Dictionary) As pgReQ_request
		  // sends a response to a request waiting to be handled in the RequestsReceived queue
		  // whatever you place in the response Dictionary is appended to the payload dictionary of the request
		  
		  if IsNull(pgSession) then return new pgReQ_request(true , "Null database session")
		  if IsNull(response) then return new pgReQ_request(true , "Invalid response")
		  if response.Count = 0 then return new pgReQ_request(true, "Blank response")
		  
		  dim request2respond as pgReQ_request = getRequestReceived(UUID)
		  if request2respond.Error then Return new pgReQ_request(true , "UUID not found among the requests waiting to be handled")
		  
		  for i as Integer = 0 to response.Count - 1
		    request2respond.setParameter(response.Key(i).StringValue , response.Value(response.Key(i).StringValue))
		  next i
		  
		  request2respond.responderPID = mCurrentPID
		  request2respond.responseStamp = new date
		  
		  dim json as String = request2respond.toJSON
		  
		  dim NOTIFY as string = "NOTIFY " + request2respond.ResponseChannel + " , '" + json + "'"
		  pgSession.SQLExecute(NOTIFY)
		  
		  if pgSession.Error then
		    request2respond.Error = true
		    request2respond.ErrorMessage = "Error sending request: " + pgSession.ErrorMessage
		  else
		    request2respond.Error = False
		    request2respond.ErrorMessage = ""
		    dim idx as Integer = getRequestReceivedIDX(UUID)
		    if idx >= 0 then RequestsReceived.Remove(idx)
		  end if
		  
		  Return request2respond
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function verifyLimnie() As string
		  dim conf as RecordSet = pgSession.SQLSelect("SELECT * FROM thirdway.conf WHERE key = 'limnie_path'")
		  
		  if pgSession.Error then return "Error reading Limnie path"
		  if conf.RecordCount = 0 then return "No limnie_path defined in conf"
		  if conf.Field("value").StringValue.Trim = "" then return "limnie_path is blank"
		  
		  dim limnie_path as String = conf.Field("value").StringValue
		  dim LimnieFile as FolderItem = GetFolderItem(limnie_path)
		  
		  if IsNull(LimnieFile) then return "Limnie file is invalid"
		  
		  dim LimnieVFS as new Limnie.VFS
		  LimnieVFS.file = LimnieFile
		  
		  dim testLimnie as new Limnie.Session(LimnieVFS)
		  
		  if testLimnie.getLastError <> "" then return "Limnie error: " + testLimnie.getLastError
		  
		  testLimnie.Close // we don't need it anymore
		  
		  Return ""
		  
		End Function
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event ServiceInterrupted(errorMsg as string)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event WriteLog(message as string)
	#tag EndHook


	#tag Property, Flags = &h21
		Private ChannelsListening() As String
	#tag EndProperty

	#tag Property, Flags = &h21
		#tag Note
			used by PollTimerAction
		#tag EndNote
		Private LastSecond As int64
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCurrentPID As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As string
	#tag EndProperty

	#tag Property, Flags = &h21
		Private pgSession As PostgreSQLDatabase
	#tag EndProperty

	#tag Property, Flags = &h21
		Private queuePollTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RequestDeclarations() As pgReQ_request
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RequestsAwaitingResponse() As pgReQ_request
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RequestsReceived() As pgReQ_request
	#tag EndProperty

	#tag Property, Flags = &h21
		Private ResponsesReceived() As pgReQ_request
	#tag EndProperty

	#tag Property, Flags = &h21
		#tag Note
			used by PollTimerAction
		#tag EndNote
		Private VerifyServiceCounter As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private WorkerPool(-1) As thirdwayControllerWorker
	#tag EndProperty


	#tag Constant, Name = fragmentSize, Type = Double, Dynamic = False, Default = \"8", Scope = Private
	#tag EndConstant

	#tag Constant, Name = MByte, Type = Double, Dynamic = False, Default = \"1048576", Scope = Private
	#tag EndConstant

	#tag Constant, Name = PollTimerPeriod, Type = Double, Dynamic = False, Default = \"250", Scope = Public
	#tag EndConstant

	#tag Constant, Name = VerifyServiceIntervalMultiplier, Type = Double, Dynamic = False, Default = \"240", Scope = Public
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
