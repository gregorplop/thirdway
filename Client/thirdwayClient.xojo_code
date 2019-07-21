#tag Class
Protected Class thirdwayClient
	#tag Method, Flags = &h0
		Function CacheDocument(UUID as String) As string
		  // calling this method instructs the controller to upload the content to the content cache table (thirdway.cache)
		  // it's up to the app to fetch the content locally
		  // returns request uuid or empty string for error: for error message read LastError
		  // IF the document is already cached, it will return the document UUID instead of the Request UUID (because there is no request made!)
		  // ...in this case, do not wait for the PullConcluded event (it will never arrive), just fetch the data directly from the cache
		  
		  if busy then 
		    mLastError = "Client is busy doing some other I/O at the moment"
		    Return ""
		  else
		    busy = true
		  end if
		  
		  if not isUUID(UUID) then 
		    mLastError = "Document ID is not a valid UUID"
		    busy = false
		    Return ""
		  end if
		  
		  // check if the document exists and is valid
		  dim repoSurvey as RecordSet = pgSession.SQLSelect("SELECT valid FROM thirdway.repository WHERE docid = '" + UUID + "'")
		  if pgSession.Error then
		    mLastError = "Database error while surveying repository: " + pgSession.ErrorMessage
		    busy = false
		    Return ""
		  end if
		  
		  if repoSurvey.RecordCount = 0 then
		    mLastError = "Document does not exist in repository"
		    busy = false
		    Return ""
		  end if
		  
		  if repoSurvey.Field("valid").BooleanValue = false then
		    mLastError = "Document is marked as invalid"
		    busy = false
		    return ""
		  end if
		  
		  
		  // check if document is already in the content cache --if it is then there is no need to ask the controller to fetch it from the Limnie
		  
		  dim cacheSurvey as RecordSet = pgSession.SQLSelect("SELECT indx , lastfragment FROM thirdway.cache WHERE docid = '" + UUID + "' AND action = 'retain' ORDER BY indx ASC")
		  if pgSession.Error then
		    mLastError = "Database error while surveying cache: " + pgSession.ErrorMessage
		    busy = false
		    Return ""
		  end if
		  
		  // if we have something valid in cache then check if all fragments are in order
		  dim i as Integer = 1
		  dim contentCached as Boolean = true
		  
		  while not cacheSurvey.EOF
		    
		    if cacheSurvey.Field("indx").IntegerValue <> i then  // some fragment's missing
		      contentCached = false
		      exit while
		    end if
		    
		    i = i + 1
		    cacheSurvey.MoveNext
		  wend
		  
		  if cacheSurvey.Field("lastfragment").BooleanValue = false and contentCached = true then
		    contentCached = False
		  end if
		  
		  if contentCached = true then
		    Return UUID  // as noted before, this indicates an already cached document, no request is made to the controller
		  end if
		  
		  // we now need to make a request to the controller to fetch a document from the Limnie and upload it to the content cache
		  
		  
		  
		  // 
		  // dim pullRequest as new pgReQ_request("PULL" , timeoutPeriod , true)
		  // importRequest.UUID = ActivePushjob.UUID  // request UUID = document UUID, because why the heck not?
		  // importRequest.RequestChannel = "thirdway_controller"  // send it there
		  // importRequest.ResponseChannel = "thirdway_" + str(mCurrentPID)  // as set in constructor
		  // 
		  // importRequest = sendRequest(importRequest)
		  // 
		  // if importRequest.Error then
		  // rollback = rollbackPush(ActivePushjob.UUID)
		  // importRequest.ErrorMessage = importRequest.ErrorMessage + " / Rollback " + if(rollback = true , "OK" , "fail")
		  // RaiseEvent PushConcluded(importRequest)
		  // busy = False
		  // Return
		  // end if
		  
		  busy = false
		  
		  // out of our hands now: 
		  // it's up to the controller to respond and conclude the pull-to-cache 
		  // if the controller does not respond then the pull will timeout sometime later
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
		  
		  pgSession.SQLExecute("LISTEN thirdway_" + str(mCurrentPID))
		  if pgSession.Error then
		    mLastError = "Error initiating listening"
		    Return
		  end if
		  
		  // just an example of declaring requests this session (thirdway client) will have to process
		  RequestDeclarations.Append new pgReQ_request("SHUTDOWN" , 120 , false) 
		  
		  AddHandler pgSession.ReceivedNotification , WeakAddressOf pgSessionReceiveNotification
		  
		  queuePollTimer = new Timer
		  queuePollTimer.Period = PollTimerPeriod
		  AddHandler queuePollTimer.Action , WeakAddressOf PollTimerAction
		  queuePollTimer.Mode = timer.ModeMultiple
		  
		  pushThread = new Thread
		  AddHandler pushThread.Run , WeakAddressOf PushThreadAction
		  
		  mLastError = ""
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CreateDocument(source as Readable, dbRecord as DatabaseRecord, optional remainCached as Boolean = true) As string
		  // returns document uuid or empty string for error: for error message read LastError
		  
		  if busy then
		    mLastError = "client is still busy"
		    Return ""
		  end if
		  
		  if IsNull(source) then
		    mLastError = "data source is invalid"
		    Return ""
		  end if
		  
		  if IsNull(dbRecord) then
		    mLastError = "record data is invalid"
		    Return ""
		  end if
		  
		  dim docUUID as String = getUUID  
		  
		  ActivePushjob = new PushJob(source , dbRecord , docUUID , remainCached)  // only one is allowed at any given time
		  pushThread.Run // start uploading to cache
		  
		  Return docUUID  // inform the app that this is being processed. it should expect an event when done/fail/timeout
		  
		  
		  
		End Function
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

	#tag Method, Flags = &h21
		Private Sub PushThreadAction(sender as Thread)
		  busy = true
		  dim bytes2read as Integer = MByte * fragmentSize  // this has to be the same across all clients/controller/limnes
		  dim msecs as Int64 = Microseconds / 1000  // part of measuring how long the push lasts for
		  
		  // prepare a failure response for use if some error occurs before sending the actual request to the controller
		  dim failResponse as new pgReQ_request("PUSH" , 0 , true)
		  failResponse.Error = False  // let's clarify here: this signifies message queue error, not application error. application error in this case should be sought in thirdway_errormsg payload parameter
		  failResponse.creationStamp = date(new date)
		  failResponse.ErrorMessage = ""  // application error message in thirdway_errormsg
		  failResponse.initiatorPID = mCurrentPID
		  failResponse.processing = false
		  failResponse.MyOwnRequest = true
		  failResponse.RequestChannel = "thirdway_controller"  // or whatever the controller is listening to
		  failResponse.RequireResponse = true
		  failResponse.ResponseChannel = "thirdway_" + str(mCurrentPID)
		  failResponse.responderPID = mCurrentPID  // this is the only way to distinguish a pre-import failure: it will come from the client's PID, not the controller's
		  failResponse.responseStamp = date(new date)
		  failResponse.UUID = ActivePushjob.UUID  // request UUID = document UUID, because why the heck not?
		  // ready to send ... we'll see why this is necessary right below
		  
		  // build the repository document record
		  ActivePushjob.dbRecord.Column("docid") = ActivePushjob.UUID  // the doc UUID for the push
		  ActivePushjob.dbRecord.Int64Column("importduration") = msecs
		  ActivePushjob.dbRecord.BooleanColumn("valid") = false  // this is the initial form of the document record, things haven't settled yet--most notably: the docid
		  // we expect the app to have filled the userdata column  --but NOT any of the above. also creationstamp is filled automatically
		  pgSession.InsertRecord("thirdway.repository" , ActivePushjob.dbRecord)  
		  if pgSession.Error then
		    failResponse.setParameter("thirdway_errormsg" , "Error creating repository document record: " + pgSession.ErrorMessage)
		    RaiseEvent PushConcluded(failResponse)  // this is what the response we've been handcrafting is for: failure before involving the controller
		    busy = false
		    return  // quit pushing, we can't even create the record on the repository table
		  end if
		  
		  // at this point we can begin uploading the binary data from the stream
		  
		  dim cacheFragment as DatabaseRecord
		  dim fragmentData as string
		  dim indx as Integer = 1
		  dim rollback as Boolean
		  dim dataPushed as Int64 = 0
		  dim timeoutPeriod as Integer
		  
		  do until ActivePushjob.source.EOF
		    
		    fragmentData = ActivePushjob.source.Read(bytes2read)  // get a fragment
		    
		    if ActivePushjob.source.ReadError then
		      rollback = rollbackPush(ActivePushjob.UUID)
		      failResponse.setParameter("thirdway_errormsg" , "Error reading from data source / Rollback " + if(rollback = true , "OK" , "fail"))
		      RaiseEvent PushConcluded(failResponse)
		      busy = false
		      return
		    end if
		    
		    cacheFragment = new DatabaseRecord
		    
		    cacheFragment.Column("fragmentid") = getUUID   // every fragment has its own unique id
		    cacheFragment.Column("docid") = ActivePushjob.UUID
		    cacheFragment.IntegerColumn("indx") = indx
		    cacheFragment.BooleanColumn("lastfragment") = if(ActivePushjob.source.EOF , true , false)
		    cacheFragment.Column("action") = "push"
		    cacheFragment.BlobColumn("content") = fragmentData
		    
		    pgSession.InsertRecord("thirdway.cache" , cacheFragment)
		    
		    if pgSession.Error then
		      rollback = rollbackPush(ActivePushjob.UUID)
		      failResponse.setParameter("thirdway_errormsg" , "Error creating fragment on cache: " + pgSession.ErrorMessage + " / Rollback " + if(rollback = true , "OK" , "fail"))
		      RaiseEvent PushConcluded(failResponse)  // this is what the response we've been handcrafting is for: failure before involving the controller
		      busy = false
		      return  // we're done with the push
		    end if
		    
		    indx = indx + 1
		    dataPushed = dataPushed + fragmentData.Len  // in bytes
		  loop
		  
		  // write the bytesize to the document record
		  pgSession.SQLExecute("UPDATE thirdway.repository SET bytesize = " + str(dataPushed) + " WHERE docid = '" + ActivePushjob.UUID + "'")
		  if pgSession.Error then
		    failResponse.setParameter("thirdway_errormsg" , "Error updating repository document record: " + pgSession.ErrorMessage)
		    RaiseEvent PushConcluded(failResponse)  // this is what the response we've been handcrafting is for: failure before involving the controller
		    busy = false
		    return  // quit pushing
		  end if
		  
		  dataPushed = Round(dataPushed / 1000000) // now in MB and rounded
		  timeoutPeriod = if(dataPushed < 50 , 60 , dataPushed * 1.2) // this is purely speculative
		  
		  //now we need to ask the controller to import whatever's in the cache into the limnie and finalize the repository record
		  
		  dim importRequest as new pgReQ_request("PUSH" , timeoutPeriod , true)
		  importRequest.UUID = ActivePushjob.UUID  // request UUID = document UUID, because why the heck not?
		  importRequest.RequestChannel = "thirdway_controller"  // send it there
		  importRequest.ResponseChannel = "thirdway_" + str(mCurrentPID)  // as set in constructor
		  importRequest.setParameter("remaincached" , ActivePushjob.remainCached)  // this instructs the controller to leave it in cache after importing into the limnie
		  
		  importRequest = sendRequest(importRequest)
		  
		  if importRequest.Error then
		    rollback = rollbackPush(ActivePushjob.UUID)
		    importRequest.ErrorMessage = importRequest.ErrorMessage + " / Rollback " + if(rollback = true , "OK" , "fail")
		    RaiseEvent PushConcluded(importRequest)
		    busy = False
		    Return
		  end if
		  
		  busy = false
		  
		  // out of our hands now: 
		  // it's up to the controller to respond and conclude the push: 
		  // if the controller does not respond then the push will timeout sometime later
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub RequestExpired(ExpiredRequest as pgReQ_request)
		  select case ExpiredRequest.Type
		    
		  case "PUSH"
		    dim rollback as Boolean = rollbackPush(ExpiredRequest.UUID)
		    ExpiredRequest.Error = true
		    ExpiredRequest.ErrorMessage = "Request Expired / Rollback " + if(rollback = true , "OK" , "fail")
		    RaiseEvent PushConcluded(ExpiredRequest.clone)
		    
		  end select
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub RequestReceived(UUID as String)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub ResponseReceived(UUID as String)
		  dim thisJustIn as pgReQ_request = popResponse(UUID)
		  
		  select case thisJustIn.Type
		    
		  case "PUSH"
		    
		    RaiseEvent PushConcluded(thisJustIn)
		    
		  end select
		  
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


	#tag Hook, Flags = &h0
		Event PullConcluded(requestData as pgReQ_request)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event PushConcluded(requestData as pgReQ_request)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ServiceInterrupted(errorMsg as string)
	#tag EndHook


	#tag Property, Flags = &h21
		Private ActivePushjob As PushJob
	#tag EndProperty

	#tag Property, Flags = &h21
		Private busy As Boolean
	#tag EndProperty

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
		Private pushThread As Thread
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
