#tag Class
Protected Class VFS
	#tag Method, Flags = &h0
		Sub Constructor(optional initialErrorMessage as string = "")
		  if initialErrorMessage.Trim = empty then
		    error = False
		    errorMessage = empty
		  else
		    error = true
		    errorMessage = initialErrorMessage
		  end if
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		description As string
	#tag EndProperty

	#tag Property, Flags = &h0
		error As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		errorMessage As String
	#tag EndProperty

	#tag Property, Flags = &h0
		file As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h0
		friendlyName As String
	#tag EndProperty

	#tag Property, Flags = &h0
		hostname As String
	#tag EndProperty

	#tag Property, Flags = &h0
		initStamp As date
	#tag EndProperty

	#tag Property, Flags = &h0
		name As String
	#tag EndProperty

	#tag Property, Flags = &h0
		password As string
	#tag EndProperty

	#tag Property, Flags = &h0
		uuid As String
	#tag EndProperty

	#tag Property, Flags = &h0
		version As string
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="name"
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
			Name="description"
			Group="Behavior"
			Type="string"
			EditorType="MultiLineEditor"
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
			Name="friendlyName"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="password"
			Group="Behavior"
			Type="string"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="uuid"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="version"
			Group="Behavior"
			Type="string"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="hostname"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
