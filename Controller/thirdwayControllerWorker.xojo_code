#tag Class
Protected Class thirdwayControllerWorker
Inherits Thread
Implements Readable,Writeable
	#tag Event
		Sub Run()
		  // process whatever's in the currentRequest
		  select case currentRequest.Type
		  case "PUSH"
		    
		    dim initReadableError as String = initReadable
		    if initReadableError <> "" then
		      RaiseEvent Respond(currentRequest.UUID , new Dictionary("thirdway_errormsg":initReadableError))
		      busy = false
		      return
		    end if
		    
		    dim remainCached as Boolean = currentRequest.getParameter("remaincached").BooleanValue
		    
		    // remember: this class implements the Readable interface so as to do these imports
		    dim newDocument as Limnie.Document = LimnieSession.createDocument(me , "defaultpool" , "thirdway object" , true , nil , currentRequest.UUID)
		    
		    if newDocument.error then
		      // delete cached data perhaps?
		      RaiseEvent Respond(currentRequest.UUID , new dictionary("thirdway_errormsg" : newDocument.ErrorMessage))
		      return
		    end if
		    
		    // written content to limnie
		    
		    pgsession.SQLExecute("BEGIN TRANSACTION")
		    if pgsession.Error then
		      // delete cached data perhaps?
		      RaiseEvent Respond(currentRequest.UUID , new dictionary("thirdway_errormsg" : "Error starting housekeeping on new document: " + pgSession.ErrorMessage))
		      return
		    end if
		    
		    pgsession.SQLExecute("UPDATE thirdway.repository SET valid = TRUE where docid = '" + currentRequest.UUID + "'")
		    if pgsession.Error then
		      // delete cached data perhaps?
		      RaiseEvent Respond(currentRequest.UUID , new dictionary("thirdway_errormsg" : "Error activating new document: " + pgSession.ErrorMessage))
		      return
		    end if
		    
		    pgsession.SQLExecute("UPDATE thirdway.cache SET action = 'retain' WHERE docid = '" + currentRequest.UUID + "'")
		    if pgsession.Error then
		      // delete cached data perhaps?
		      RaiseEvent Respond(currentRequest.UUID , new dictionary("thirdway_errormsg" : "Error updating cache status: " + pgSession.ErrorMessage))
		      return
		    end if
		    
		    pgsession.SQLExecute("COMMIT")
		    if pgsession.Error then
		      // delete cached data perhaps?
		      RaiseEvent Respond(currentRequest.UUID , new dictionary("thirdway_errormsg" : "Error finalizing document import: " + pgSession.ErrorMessage))
		      return
		    end if
		    
		    if currentRequest.getParameter("remaincached").BooleanValue = false then
		      call clearCache(currentRequest.UUID)  // don't bother with the outcome of this
		    end if
		    
		    RaiseEvent Respond(currentRequest.UUID , new dictionary("complete" : true))
		    
		    
		    
		  end select
		  
		  
		  
		  
		  busy = false
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Function clearCache(UUID as string) As Boolean
		  pgSession.SQLExecute("DELETE FROM thirdway.cache WHERE docid = '" + UUID + "'")
		  Return not pgsession.Error
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(newSession as PostgreSQLDatabase)
		  mLastError = ""
		  currentIO_mode = IO_Mode.undefined
		  
		  pgsession = newSession
		  
		  if pgsession.Connect = false then
		    mLastError = "init error: " + pgsession.ErrorMessage
		    Return
		  end if
		  
		  // postgres session is now open
		  
		  // connect to the limnie
		  
		  dim conf as RecordSet = pgSession.SQLSelect("SELECT * FROM thirdway.conf WHERE key = 'limnie_path'")
		  
		  if pgSession.Error then 
		    mLastError =  "Error reading Limnie path"
		    Return
		  end if
		  
		  if conf.RecordCount = 0 then 
		    mLastError = "No limnie_path defined in conf"
		    Return
		  end if
		  
		  if conf.Field("value").StringValue.Trim = "" then 
		    mLastError =  "limnie_path is blank"
		    Return
		  end if
		  
		  dim limnie_path as String = conf.Field("value").StringValue
		  dim LimnieFile as FolderItem = GetFolderItem(limnie_path)
		  
		  if IsNull(LimnieFile) then 
		    mLastError =  "Limnie file is invalid"
		    Return
		  end if
		  
		  dim LimnieVFS as new Limnie.VFS
		  LimnieVFS.file = LimnieFile
		  LimnieSession = new Limnie.Session(LimnieVFS)
		  
		  if LimnieSession.getLastError <> "" then 
		    mLastError = "Limnie error: " + LimnieSession.getLastError
		    Return
		  end if
		  
		  // limnie is now open
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function EOF() As Boolean
		  // Part of the Readable interface.
		  
		  if readable_NextFragment > readable_LastFragment then
		    Return true
		  else
		    return False
		  end if
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Flush()
		  // Part of the Writeable interface.
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function initReadable() As string
		  
		  readable_LastFragment = 0
		  Readable_nextFragment = 1
		  
		  dim surveyQuery as string
		  
		  // the idea is to verify that everything's allright in the cache
		  surveyQuery = "SELECT cache.indx , cache.lastfragment , cache.action FROM thirdway.cache cache INNER JOIN thirdway.repository repository ON cache.docid = repository.docid"
		  surveyQuery = surveyQuery + " WHERE cache.docid = '" + currentRequest.UUID + "'"
		  surveyQuery = surveyQuery + " AND repository.valid = FALSE AND cache.action = 'push'"
		  surveyQuery = surveyQuery + " ORDER BY cache.indx ASC"
		  
		  dim fragmentData as RecordSet = pgsession.SQLSelect(surveyQuery)
		  
		  if pgsession.Error then Return "Cache error: database error"
		  if fragmentData.RecordCount = 0 then return "Cache error: No data found"
		  
		  while not fragmentData.EOF
		    
		    if fragmentData.Field("indx").IntegerValue <> readable_nextFragment then  // something's missing
		      Return "Cache error: missing fragment " + str(readable_nextFragment)
		    end if
		    
		    readable_nextFragment = readable_nextFragment + 1
		    fragmentData.MoveNext
		  wend
		  
		  readable_lastFragment = readable_nextFragment - 1
		  readable_nextFragment = 1
		  readable_ReadErrorMessage = ""
		  
		  currentIO_mode = IO_Mode.push
		  
		  return ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function isBusy() As Boolean
		  return busy
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As String
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ProcessRequest(incomingRequest as pgReQ_request)
		  busy = true
		  currentRequest = incomingRequest
		  Run  // start processing in the thread
		  
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Read(Count As Integer, encoding As TextEncoding = Nil) As String
		  // Part of the Readable interface.
		  
		  // we ignore count and encoding
		  // we send out a fragment every time this method is called. fragments are fixed in size, so it's pointless to specify length
		  
		  if readable_ReadErrorMessage <> "" then return ""
		  
		  dim fragmentData as RecordSet = pgsession.SQLSelect("SELECT * FROM thirdway.cache WHERE docid = '" + currentRequest.UUID + "' AND indx = " + str(readable_NextFragment))
		  
		  if pgsession.Error then
		    readable_ReadErrorMessage = "Error reading fragment from the cache"
		    mLastError = readable_ReadErrorMessage
		    return ""
		  end if
		  
		  if fragmentData.RecordCount <> 1 then
		    readable_ReadErrorMessage = "Fragment " + str(readable_NextFragment) + " should have a single record in cache"
		    mLastError = readable_ReadErrorMessage
		    return ""
		  end if
		  
		  readable_NextFragment = readable_NextFragment + 1
		  
		  Return fragmentData.Field("content").StringValue
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadError() As Boolean
		  // Part of the Readable interface.
		  
		  if readable_ReadErrorMessage = "" then
		    return false
		  else
		    return true
		  end if
		  
		End Function
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

	#tag Method, Flags = &h1
		Protected Sub Write(text As String)
		  // Part of the Writeable interface.
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  
		  
		End Function
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Respond(UUID as String, response as Dictionary)
	#tag EndHook


	#tag Property, Flags = &h21
		Private busy As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		currentIO_mode As IO_Mode
	#tag EndProperty

	#tag Property, Flags = &h21
		Private currentRequest As pgReQ_request
	#tag EndProperty

	#tag Property, Flags = &h21
		Private LimnieSession As Limnie.Session
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private pgsession As PostgreSQLDatabase
	#tag EndProperty

	#tag Property, Flags = &h21
		Private readable_LastFragment As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private readable_NextFragment As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private readable_ReadErrorMessage As string
	#tag EndProperty


	#tag Enum, Name = IO_Mode, Type = Integer, Flags = &h0
		push
		  pull
		undefined
	#tag EndEnum


	#tag ViewBehavior
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			Type="String"
			EditorType="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			Type="Integer"
			EditorType="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			Type="String"
			EditorType="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Priority"
			Visible=true
			Group="Behavior"
			InitialValue="5"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="StackSize"
			Visible=true
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="currentIO_mode"
			Group="Behavior"
			Type="IO_Mode"
			EditorType="Enum"
			#tag EnumValues
				"0 - push"
				"1 - pull"
				"2 - undefined"
			#tag EndEnumValues
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
