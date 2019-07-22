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
		      pgsession.SQLExecute("ROLLBACK")
		      RaiseEvent Respond(currentRequest.UUID , new dictionary("thirdway_errormsg" : "Error activating new document: " + pgSession.ErrorMessage))
		      return
		    end if
		    
		    pgsession.SQLExecute("UPDATE thirdway.cache SET action = 'retain' WHERE docid = '" + currentRequest.UUID + "'")
		    if pgsession.Error then
		      // delete cached data perhaps?
		      pgsession.SQLExecute("ROLLBACK")
		      RaiseEvent Respond(currentRequest.UUID , new dictionary("thirdway_errormsg" : "Error updating cache status: " + pgSession.ErrorMessage))
		      return
		    end if
		    
		    pgsession.SQLExecute("COMMIT")
		    if pgsession.Error then
		      // delete cached data perhaps?
		      pgsession.SQLExecute("ROLLBACK")
		      RaiseEvent Respond(currentRequest.UUID , new dictionary("thirdway_errormsg" : "Error finalizing document import: " + pgSession.ErrorMessage))
		      return
		    end if
		    
		    if currentRequest.getParameter("remaincached").BooleanValue = false then
		      call clearCache(currentRequest.UUID)  // don't bother with the outcome of this
		    end if
		    
		    RaiseEvent Respond(currentRequest.UUID , new dictionary("complete" : true))
		    
		    
		    
		  case "PULL"  // pulls a document out of the limnie into the cache (thirdway.cache)
		    
		    dim docid as String = currentRequest.getParameter("docid").StringValue
		    
		    initWriteable
		    
		    dim cachedDocument as Limnie.Document = LimnieSession.readDocument(me , "defaultpool" , docid.Uppercase , true)
		    
		    if cachedDocument.error then
		      call clearCache(docid)
		      RaiseEvent Respond(currentRequest.UUID , new Dictionary("thirdway_errormsg" : "Object storage error: " + cachedDocument.ErrorMessage + " : " + writeable_writeErrorMessage))
		      Return
		    end if
		    
		    Flush  // finalize cache records for document
		    
		    if WriteError then
		      call clearCache(docid)
		      RaiseEvent Respond(currentRequest.UUID , new Dictionary("thirdway_errormsg" : "Error finalizing cache: " + writeable_WriteErrorMessage))
		      Return
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
		  // you MUST call this when the last fragment has been written in order to finalize the last cache record (ie set its lastfragment = true)
		  // calling it signifies the end of the operatin
		  
		  writeable_WriteErrorMessage = ""
		  
		  dim docid as string = currentRequest.getParameter("docid").StringValue
		  
		  pgsession.SQLExecute("UPDATE thirdway.cache SET lastfragment = TRUE WHERE fragmentid = '" + writeable_LastFragmentUUID + "'")
		  
		  if pgsession.Error then 
		    writeable_WriteErrorMessage = "Error updating lastfragment flag: " + pgsession.ErrorMessage
		    Return
		  end if
		  
		  pgsession.SQLExecute("UPDATE thirdway.cache SET action = 'retain' WHERE docid = '" + docid + "'")
		  
		  if pgsession.Error then 
		    writeable_WriteErrorMessage = "Error updating cache action flag: " + pgsession.ErrorMessage
		    Return
		  end if
		  
		  
		End Sub
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
		Private Function initReadable() As string
		  // the readable interface in this class is used to treat the cache table as a read stream for a specific document...
		  // ...and feed it to the Limnie. The Limnie write method accepts anything implementing the readable interface as input
		  
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

	#tag Method, Flags = &h21
		Private Sub initWriteable()
		  writeable_NextFragment = 1
		  writeable_WriteErrorMessage = ""
		  
		End Sub
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
		  
		  dim FragmentUUID as String = getUUID
		  dim now as new date
		  dim docid as string = currentRequest.getParameter("docid").StringValue
		  
		  if FragmentUUID = "" then 
		    writeable_WriteErrorMessage = "Error generating fragment UUID"
		    return
		  end if
		  
		  dim newCacheRecord as new DatabaseRecord
		  
		  newCacheRecord.Column("fragmentid") = FragmentUUID
		  newCacheRecord.DateColumn("creationstamp") = now
		  newCacheRecord.Column("docid") = docid
		  newCacheRecord.IntegerColumn("indx") = writeable_NextFragment
		  newCacheRecord.BooleanColumn("lastfragment") = False
		  newCacheRecord.Column("action") = "pull"
		  newCacheRecord.BlobColumn("content") = Text
		  
		  pgsession.InsertRecord("thirdway.cache" , newCacheRecord)
		  
		  if pgsession.Error then
		    writeable_WriteErrorMessage = "Error writing cache record: " + pgsession.ErrorMessage
		    Return
		  end if
		  
		  writeable_NextFragment = writeable_NextFragment + 1
		  writeable_LastFragmentUUID = FragmentUUID
		  writeable_WriteErrorMessage = ""
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function WriteError() As Boolean
		  // Part of the Writeable interface.
		  
		  if writeable_WriteErrorMessage = "" then
		    return false
		  else
		    return true
		  end if
		  
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

	#tag Property, Flags = &h21
		Private writeable_LastFragmentUUID As string
	#tag EndProperty

	#tag Property, Flags = &h21
		Private writeable_NextFragment As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private writeable_WriteErrorMessage As String
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
