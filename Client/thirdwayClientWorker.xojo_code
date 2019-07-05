#tag Class
Protected Class thirdwayClientWorker
Inherits Thread
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
			Name="UUID"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="remainCached"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
