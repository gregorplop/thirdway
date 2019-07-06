#tag Class
Protected Class PushJob
	#tag Method, Flags = &h0
		Sub Constructor(byref initSource as Readable, byref initDBrecord as DatabaseRecord, initUUID as string, initRemainCached as Boolean)
		  source = initSource
		  dbRecord = initDBrecord
		  UUID = initUUID
		  remainCached = initRemainCached
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		dbRecord As DatabaseRecord
	#tag EndProperty

	#tag Property, Flags = &h0
		remainCached As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		source As Readable
	#tag EndProperty

	#tag Property, Flags = &h0
		UUID As String
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
	#tag EndViewBehavior
End Class
#tag EndClass
