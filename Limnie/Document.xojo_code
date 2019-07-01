#tag Class
Protected Class Document
	#tag Method, Flags = &h0
		Sub Constructor(optional initialErrorMessage as string = "", optional customErrorCode as Integer = 1)
		  if initialErrorMessage.Trim = empty then
		    error = False
		    errorMessage = empty
		    errorCode = 0
		  else
		    error = true
		    errorMessage = initialErrorMessage
		    errorCode = customErrorCode  // error code is needed in at least one method return this class
		  end if
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function isLocked() As Boolean
		  for i as integer = 0 to fragments.Ubound
		    if isnull(fragments(i)) = true then return true
		    if fragments(i).locked = true then return true
		  next i
		  
		  return false
		  
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		creationStamp As date
	#tag EndProperty

	#tag Property, Flags = &h0
		deleted As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		error As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		errorCode As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		errorMessage As String
	#tag EndProperty

	#tag Property, Flags = &h0
		fragmented As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		fragments(-1) As Limnie.Fragment
	#tag EndProperty

	#tag Property, Flags = &h0
		hash As String
	#tag EndProperty

	#tag Property, Flags = &h0
		lastChangeStamp As Date
	#tag EndProperty

	#tag Property, Flags = &h0
		metadatum As String
	#tag EndProperty

	#tag Property, Flags = &h0
		objidx As Int64
	#tag EndProperty

	#tag Property, Flags = &h0
		pool As string
	#tag EndProperty

	#tag Property, Flags = &h0
		size As Int64
	#tag EndProperty

	#tag Property, Flags = &h0
		uuid As string
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
			Name="deleted"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="error"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="errorMessage"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="fragmented"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="hash"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="metadatum"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="objidx"
			Group="Behavior"
			Type="Int64"
		#tag EndViewProperty
		#tag ViewProperty
			Name="pool"
			Group="Behavior"
			Type="string"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="size"
			Group="Behavior"
			Type="Int64"
		#tag EndViewProperty
		#tag ViewProperty
			Name="uuid"
			Group="Behavior"
			Type="string"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="errorCode"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
