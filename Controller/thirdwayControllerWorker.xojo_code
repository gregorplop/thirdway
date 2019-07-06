#tag Class
Protected Class thirdwayControllerWorker
Inherits Thread
	#tag Event
		Sub Run()
		  // process whatever's in the currentRequest
		  
		  
		  RaiseEvent Respond(currentRequest.UUID , new Dictionary("thirdway_errormsg":"worker thread error"))
		  
		  
		  busy = false
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Constructor(newSession as PostgreSQLDatabase)
		  mLastError = ""
		  pgsession = newSession
		  
		  if pgsession.Connect = false then
		    mLastError = "init error: " + pgsession.ErrorMessage
		  end if
		  
		  
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


	#tag Hook, Flags = &h0
		Event Respond(UUID as String, response as Dictionary)
	#tag EndHook


	#tag Property, Flags = &h21
		Private busy As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private currentRequest As pgReQ_request
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private pgsession As PostgreSQLDatabase
	#tag EndProperty


	#tag Enum, Name = actions, Type = Integer, Flags = &h0
		push
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
	#tag EndViewBehavior
End Class
#tag EndClass
