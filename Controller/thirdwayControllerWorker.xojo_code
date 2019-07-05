#tag Class
Protected Class thirdwayControllerWorker
Inherits Thread
	#tag Event
		Sub Run()
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Constructor(dbCredentials as Dictionary)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ProcessRequest(incomingRequest as pgReQ_request)
		  
		  System.DebugLog("worker - process request: " + incomingRequest.UUID)
		  
		  incomingRequest.Error = true
		  incomingRequest.ErrorMessage = "test error!"
		  
		  dim d as new Dictionary
		  d.Value("test") = "testtest"
		  
		  RaiseEvent Respond(incomingRequest.UUID , d)
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

	#tag Property, Flags = &h0
		LastError As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private pgsession As PostgreSQLDatabase
	#tag EndProperty

	#tag Property, Flags = &h0
		Untitled As Integer
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
		#tag ViewProperty
			Name="LastError"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Untitled"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
