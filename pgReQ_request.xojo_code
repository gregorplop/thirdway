#tag Class
Protected Class pgReQ_request
	#tag Method, Flags = &h0
		Function Clone() As pgReQ_request
		  dim clone as new pgReQ_request(Type , TimeoutCountdown , RequireResponse)
		  
		  clone.creationStamp = new date(creationStamp)
		  clone.Error = Error
		  clone.ErrorMessage = ErrorMessage
		  clone.initiatorPID = initiatorPID
		  clone.MyOwnRequest = MyOwnRequest
		  clone.payload = clonePayload
		  clone.processing = processing
		  clone.RequestChannel = RequestChannel
		  clone.responderPID = responderPID
		  clone.ResponseChannel = ResponseChannel
		  clone.responseStamp = if(IsNull(responseStamp) , nil , new date(responseStamp))
		  clone.UUID = UUID
		  
		  return clone
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function clonePayload() As Dictionary
		  dim output as new Dictionary
		  
		  for i as Integer = 0 to payload.Count - 1
		    output.Value(payload.Key(i)) = payload.Value(payload.Key(i))
		  next i
		  
		  Return output
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(initError as Boolean, initErrorMessage as String)
		  Error = initError
		  ErrorMessage = initErrorMessage
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(content as string)
		  Error = false
		  ErrorMessage = ""
		  
		  dim JSONpackage as JSONItem
		  
		  try
		    
		    JSONpackage = new JSONItem(content)
		    
		  Catch e as JSONException
		    Error = true
		    ErrorMessage = "Content is not JSON formatted"
		    Return
		  end try
		  
		  dim structureError as Boolean = False
		  
		  if JSONpackage.HasName("creationstamp") = False then structureError = true
		  if JSONpackage.HasName("error") = False then structureError = true
		  if JSONpackage.HasName("errormessage") = False then structureError = true
		  if JSONpackage.HasName("initiatorpid") = false then structureError = true
		  if JSONpackage.HasName("requestchannel") = False then structureError = true
		  if JSONpackage.HasName("requireresponse") = false then structureError = true
		  if JSONpackage.HasName("responderpid") = false then structureError = true
		  if JSONpackage.HasName("responsechannel") = false then structureError = true
		  if JSONpackage.HasName("responsestamp") = false then structureError = true
		  if JSONpackage.HasName("timeoutcountdown") = False then structureError = true
		  if JSONpackage.HasName("type") = False then structureError = true
		  if JSONpackage.HasName("uuid") = False then structureError = true
		  
		  if structureError then 
		    Error = true
		    ErrorMessage = "Content is not pgReQ compatible"
		    return
		  end if
		  
		  if JSONpackage.Value("creationstamp").StringValue = "" then
		    creationStamp = nil
		  else
		    creationStamp = new date
		    creationStamp.SQLDateTime = JSONpackage.Value("creationstamp").StringValue
		  end if
		  JSONpackage.Remove("creationstamp")
		  
		  Error = JSONpackage.Value("error").BooleanValue
		  JSONpackage.Remove("error")
		  
		  ErrorMessage = JSONpackage.Value("errormessage").StringValue
		  JSONpackage.Remove("errormessage")
		  
		  initiatorPID = JSONpackage.Value("initiatorpid").IntegerValue
		  JSONpackage.Remove("initiatorpid")
		  
		  RequestChannel = JSONpackage.Value("requestchannel").StringValue
		  JSONpackage.Remove("requestchannel")
		  
		  RequireResponse = JSONpackage.Value("requireresponse").BooleanValue
		  JSONpackage.Remove("requireresponse")
		  
		  responderPID = JSONpackage.Value("responderpid").IntegerValue
		  JSONpackage.Remove("responderpid")
		  
		  ResponseChannel = JSONpackage.Value("responsechannel").StringValue
		  JSONpackage.Remove("responsechannel")
		  
		  if JSONpackage.Value("responsestamp").StringValue = "" then
		    responseStamp = nil
		  else
		    responseStamp = new date
		    responseStamp.SQLDateTime = JSONpackage.Value("responsestamp").StringValue
		  end if
		  JSONpackage.Remove("responsestamp")
		  
		  TimeoutCountdown = JSONpackage.value("timeoutcountdown").IntegerValue
		  JSONpackage.Remove("timeoutcountdown")
		  
		  Type = JSONpackage.Value("type").StringValue
		  JSONpackage.Remove("type")
		  
		  UUID = JSONpackage.Value("uuid").StringValue
		  JSONpackage.Remove("uuid")
		  
		  // whatever's left in the package is custom parameters
		  payload = new Dictionary
		  for i as Integer = 0 to JSONpackage.Count - 1
		    payload.Value(JSONpackage.Name(i)) = JSONpackage.Value(JSONpackage.Name(i))
		  next i
		  
		  
		  
		  
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(initType as string, initTimeout as Integer, optional ExpectResponse as Boolean = true)
		  payload = new Dictionary
		  
		  if initType.Trim = "" then
		    Error = true
		    ErrorMessage = "No Type supplied in new request"
		    return
		  end if
		  
		  Type = initType
		  TimeoutCountdown = initTimeout
		  RequireResponse = ExpectResponse
		  
		  Error = false
		  ErrorMessage = ""
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getParameter(name as string) As Variant
		  if payload.HasKey(name) = false then 
		    return nil
		  else
		    return payload.value(name).StringValue 
		  end if
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function isResponse() As Boolean
		  if isnull(responseStamp) then
		    return false
		  else
		    return true
		  end if
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub setParameter(name as string, value as variant)
		  if IsNull(payload) then return
		  
		  payload.Value(name) = value
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function string2boolean(content as String) As Boolean
		  select case content.Uppercase.Trim
		  case "TRUE"
		    return true
		  case "FALSE"
		    return false
		  else
		    return false
		  end select
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function toJSON() As string
		  dim JSONpackage as new JSONItem
		  JSONpackage.Compact = true
		  JSONpackage.EscapeSlashes = true
		  
		  JSONpackage.Value("creationstamp") = if(IsNull(creationStamp) , "" , creationStamp.SQLDateTime)
		  JSONpackage.Value("error") = str(Error)
		  JSONpackage.Value("errormessage") = ErrorMessage
		  JSONpackage.Value("initiatorpid") = initiatorPID
		  //JSONpackage.Value("myownrequest") = str(MyOwnRequest)  // for local use only
		  JSONpackage.Value("requestchannel") = RequestChannel
		  JSONpackage.Value("requireresponse") = str(RequireResponse)
		  JSONpackage.Value("responderpid") = responderPID
		  JSONpackage.Value("responsechannel") = ResponseChannel
		  JSONpackage.Value("responsestamp") = if(IsNull(responseStamp) , "" , responseStamp.SQLDateTime)
		  JSONpackage.Value("timeoutcountdown") = TimeoutCountdown
		  JSONpackage.Value("type") = Type
		  JSONpackage.Value("uuid") = UUID
		  
		  for i as Integer = 0 to payload.Count - 1
		    if JSONpackage.HasName(payload.Key(i).StringValue.Lowercase) then Continue for i
		    JSONpackage.Value(payload.Key(i).StringValue) = payload.Value(payload.Key(i)).StringValue
		  next i
		  
		  Return JSONpackage.ToString
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		creationStamp As date
	#tag EndProperty

	#tag Property, Flags = &h0
		Error As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		ErrorMessage As String
	#tag EndProperty

	#tag Property, Flags = &h0
		initiatorPID As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		#tag Note
			true = This is a request this client has made
			false = This is a request this client has received and it is configured to process it
		#tag EndNote
		MyOwnRequest As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private payload As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h0
		processing As Boolean = false
	#tag EndProperty

	#tag Property, Flags = &h0
		RequestChannel As String
	#tag EndProperty

	#tag Property, Flags = &h0
		RequireResponse As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		responderPID As Integer = 0
	#tag EndProperty

	#tag Property, Flags = &h0
		ResponseChannel As String
	#tag EndProperty

	#tag Property, Flags = &h0
		responseStamp As date
	#tag EndProperty

	#tag Property, Flags = &h0
		#tag Note
			In seconds
		#tag EndNote
		TimeoutCountdown As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		Type As String
	#tag EndProperty

	#tag Property, Flags = &h0
		UUID As string
	#tag EndProperty


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
		#tag ViewProperty
			Name="Type"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="initiatorPID"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="responderPID"
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TimeoutCountdown"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="UUID"
			Group="Behavior"
			Type="string"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RequireResponse"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Error"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ErrorMessage"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="MyOwnRequest"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RequestChannel"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ResponseChannel"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="processing"
			Group="Behavior"
			InitialValue="false"
			Type="Boolean"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
