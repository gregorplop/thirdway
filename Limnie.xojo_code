#tag Module
Protected Module Limnie
	#tag Method, Flags = &h21
		Private Function bulkSQLexecute(byref sqliteDB as SQLiteDatabase, statements() as string, singleTransaction as Boolean) As string()
		  // returns an array of the same dimension as statements()
		  // each element holds the error code for the corresponding element of statements() if any. if no error then the element is empty
		  
		  dim output(-1) as string
		  
		  if sqliteDB = nil then return output
		  
		  if statements.Ubound < 0 then return output
		  
		  
		  if singleTransaction = true then 
		    sqliteDB.SQLExecute("BEGIN TRANSACTION")
		    if sqliteDB.Error then return output
		  end if
		  
		  ReDim output(statements.Ubound)
		  dim ErrorOccured as Boolean = false
		  
		  for i as integer = 0 to statements.Ubound
		    sqliteDB.SQLExecute(statements(i))
		    if sqliteDB.error then 
		      output(i) = sqliteDB.ErrorMessage
		      ErrorOccured = true
		    else
		      output(i) = empty
		    end if
		  next i
		  
		  if ErrorOccured = False then
		    if singleTransaction = true then 
		      sqliteDB.SQLExecute("COMMIT TRANSACTION")
		      if sqliteDB.Error then ErrorOccured = true
		    end if
		  end if
		  
		  if ErrorOccured = true and singleTransaction = true then
		    sqliteDB.SQLExecute("ROLLBACK TRANSACTION")
		    if sqliteDB.Error then 
		      for i as integer = 0 to output.Ubound
		        output(i) = sqliteDB.ErrorMessage  // this indicates a rollback failure
		      next i
		    end if
		  end if
		  
		  return output
		  
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function createLimnie(newVFS as Limnie.VFS) As Limnie.VFS
		  // requires:
		  // DBfile , name , friendlyname , password ,  description
		  
		  if newVFS = nil then return new Limnie.VFS("Initialization VFS object is null")
		  if newVFS.file = nil then Return  new Limnie.VFS("Invalid file path")
		  if newVFS.file.Exists = true then return new Limnie.VFS("Initialization file already exists, will not overwrite")
		  if newVFS.file.Name.NthField("." , newVFS.file.Name.CountFields(".")).Lowercase <> "limnie" then return new Limnie.VFS("Filename should have a .limnie extension")
		  
		  newVFS.name =newVFS.name.SuperTrim(true)
		  newVFS.friendlyname = newVFS.friendlyname.SuperTrim
		  newVFS.description = newVFS.description.SuperTrim
		  
		  if newVFS.name = empty then return new Limnie.VFS("New Limnie has not been named")
		  if newVFS.friendlyname = empty then return new Limnie.VFS("No friendly name for new Limnie")
		  if newVFS.description = empty then return new Limnie.VFS("No description for new Limnie")
		  
		  dim newDBobject as new SQLiteDatabase
		  newDBobject.DatabaseFile = newVFS.file
		  
		  if newVFS.password <> empty then // encrypt VFS master table
		    newDBobject.EncryptionKey = preparePassword(newVFS.password)
		  end if
		  
		  if newDBobject.CreateDatabaseFile = false then return new Limnie.VFS("Error creating Limnie: " + newDBobject.ErrorMessage)
		  // database has been created
		  
		  dim LimnieUUID as string = generateUUID
		  if LimnieUUID = empty then return new Limnie.VFS("Unable to generate unique Limnie ID")
		  
		  newVFS.name = newVFS.name.Lowercase
		  
		  dim statements(-1) as string
		  dim initStamp as new Date
		  
		  statements.Append "CREATE TABLE vfs (key TEXT UNIQUE , value1 TEXT)"
		  statements.Append "CREATE TABLE pools (uuid TEXT UNIQUE NOT NULL , name TEXT UNIQUE NOT NULL , friendlyname TEXT NOT NULL , comments TEXT , rootfolder TEXT NOT NULL , sizelimit INTEGER NOT NULL , initstamp DATETIME NOT NULL , autoexpand BOOLEAN NOT NULL , salt TEXT)"
		  statements.Append "CREATE TABLE media (uuid TEXT UNIQUE NOT NULL , pool TEXT NOT NULL , idx INTEGER NOT NULL , folder TEXT NOT NULL , threshold INTEGER NOT NULL , initstamp DATETIME NOT NULL , open BOOLEAN NOT NULL , FOREIGN KEY(pool) REFERENCES pools(name) , CONSTRAINT uniquemedium UNIQUE (pool , idx))"
		  
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('uuid' , '" + LimnieUUID + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('name' , '" + newVFS.name + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('friendlyname' , '" + newVFS.friendlyname + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('initstamp' , '" + initStamp.SQLDateTime + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('description' , '" + newVFS.description + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('version' , '" + str(LimnieVersion) + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('hostname' , '" + hostname + "')"
		  
		  dim dbinitOutcome(-1) as string = bulkSQLexecute(newDBobject , statements , false)
		  
		  if getNonEmptyElements(dbinitOutcome).Ubound >= 0 then  // there was an error initializing the Limnie
		    
		    dim ErroneusStatementIDs(-1) as integer = getNonEmptyElements(dbinitOutcome)
		    dim dbinitErrorMsg as string = "Error creating Limnie: " + EndOfLine
		    for i as integer = 0 to ErroneusStatementIDs.Ubound
		      dbinitErrorMsg = dbinitErrorMsg + statements(ErroneusStatementIDs(i)) + " --> " + dbinitOutcome(ErroneusStatementIDs(i)) + EndOfLine
		    next i
		    
		    newDBobject.Close
		    newVFS.file.Delete
		    return new Limnie.VFS("Error creating Limnie: " + dbinitErrorMsg.Trim)
		    
		  ElseIf dbinitOutcome.Ubound < 0 then  // another error
		    
		    newDBobject.close
		    newVFS.file.Delete
		    return new Limnie.VFS("Error creating Limnie: Invalid init parameters")
		    
		  end if
		  
		  newDBobject.close
		  newVFS.error = false
		  newVFS.errorMessage = empty
		  newVFS.initStamp = initStamp
		  newVFS.version = str(LimnieVersion)
		  newVFS.uuid = LimnieUUID
		  
		  return newVFS
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function generateUUID() As String
		  // Algorithm Source: https://forum.xojo.com/18856-getting-guid/0 
		  // Replace it with whatever you deem best
		  
		  if IsNull(localDB) then 
		    localDB = new SQLiteDatabase
		    if localDB.Connect = false then return empty
		  end if
		  
		  
		  Dim statement As String= "select hex( randomblob(4)) " _
		  + "|| '-' || hex( randomblob(2)) " _
		  + "|| '-' || '4' || substr( hex( randomblob(2)), 2) " _
		  + "|| '-' || substr('AB89', 1 + (abs(random()) % 4) , 1) " _
		  + "|| substr(hex(randomblob(2)), 2) " _
		  + "|| '-' || hex(randomblob(6)) AS GUID"
		  
		  dim rs as RecordSet  = localDB.SQLSelect(statement)
		  if localDB.Error then
		    Return empty
		  else
		    Return rs.Field("GUID").StringValue.Uppercase
		  end if
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function getNonEmptyElements(inputStringArray() as string) As integer()
		  dim output(-1) as integer
		  dim ArraySize as Integer = inputStringArray.Ubound
		  
		  for i as Integer = 0 to ArraySize
		    if inputStringArray(i) <> empty then output.Append i
		  next i
		  
		  return output
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function getSalt() As string
		  // Replace with your own salt (and string obfuscation mechanism)
		  // Ideally, every Limnie implementation should be compiled with its own salt value
		  
		  return "s@ltstr1ng"
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function hostname() As String
		  #If TargetWin32 then
		    
		    return System.environmentvariable("COMPUTERNAME").uppercase
		    
		  #elseif TargetLinux then
		    
		    dim hostname as new Shell
		    hostname.Mode = 0
		    hostname.Execute("hostname")
		    return hostname.ReadAll.Uppercase
		    
		  #elseif TargetMacOS then
		    
		    dim hostname as new Shell
		    hostname.Mode = 0
		    hostname.Execute("hostname")
		    return hostname.ReadAll.Uppercase
		    
		  #else
		    
		    Return empty
		    
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LimnieFileType() As FileType
		  dim LimnieType as new FileType
		  LimnieType.Name = "vfs/limnie"
		  LimnieType.MacType = "LIMNIE"
		  LimnieType.Extensions = "limnie"
		  
		  Return LimnieType
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function preparePassword(plaintext as String, optional salt as string = "") As string
		  // empty salt means use internal fixed salt via getSalt method
		  dim hash as MemoryBlock = Crypto.PBKDF2(if(salt = empty , getSalt , salt) , plaintext , 7 , 8 , Crypto.Algorithm.SHA512)
		  dim output as String
		  dim char as string
		  
		  for i as Integer = 0 to hash.Size - 1
		    char = str(hash.UInt8Value(i).ToHex(2))
		    if i mod 2 = 0 then char = char.Lowercase
		    output = output + char
		  next i
		  
		  return output  // should always be a 16 character string
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function sqlQuote(extends input as Boolean) As string
		  if input = true then
		    return "'true'"
		  else
		    return "'false'"
		  end if
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function sqlQuote(extends input() as String) As string()
		  dim output(-1) as string
		  
		  for i as integer = 0 to input.Ubound
		    output.Append input(i).sqlQuote
		  next i
		  
		  return output
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function sqlQuote(extends input as string) As string
		  if input = empty then 
		    return " NULL "
		  else
		    return " '" + input + "' "
		  end if
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SuperTrim(extends inputString as String, optional trimSpaces as Boolean = false) As String
		  dim output as String = inputString.Trim
		  
		  if trimSpaces = true then
		    output = output.ReplaceAll(" " , empty)
		  end if
		  
		  output = output.ReplaceAll("'" , empty)
		  output = output.ReplaceAll("""" , empty)
		  output = output.ReplaceAll(";" , empty)
		  
		  Return output
		  
		End Function
	#tag EndMethod


	#tag Note, Name = LICENSE
		Apache License
		                           Version 2.0, January 2004
		                        http://www.apache.org/licenses/
		
		   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION
		
		   1. Definitions.
		
		      "License" shall mean the terms and conditions for use, reproduction,
		      and distribution as defined by Sections 1 through 9 of this document.
		
		      "Licensor" shall mean the copyright owner or entity authorized by
		      the copyright owner that is granting the License.
		
		      "Legal Entity" shall mean the union of the acting entity and all
		      other entities that control, are controlled by, or are under common
		      control with that entity. For the purposes of this definition,
		      "control" means (i) the power, direct or indirect, to cause the
		      direction or management of such entity, whether by contract or
		      otherwise, or (ii) ownership of fifty percent (50%) or more of the
		      outstanding shares, or (iii) beneficial ownership of such entity.
		
		      "You" (or "Your") shall mean an individual or Legal Entity
		      exercising permissions granted by this License.
		
		      "Source" form shall mean the preferred form for making modifications,
		      including but not limited to software source code, documentation
		      source, and configuration files.
		
		      "Object" form shall mean any form resulting from mechanical
		      transformation or translation of a Source form, including but
		      not limited to compiled object code, generated documentation,
		      and conversions to other media types.
		
		      "Work" shall mean the work of authorship, whether in Source or
		      Object form, made available under the License, as indicated by a
		      copyright notice that is included in or attached to the work
		      (an example is provided in the Appendix below).
		
		      "Derivative Works" shall mean any work, whether in Source or Object
		      form, that is based on (or derived from) the Work and for which the
		      editorial revisions, annotations, elaborations, or other modifications
		      represent, as a whole, an original work of authorship. For the purposes
		      of this License, Derivative Works shall not include works that remain
		      separable from, or merely link (or bind by name) to the interfaces of,
		      the Work and Derivative Works thereof.
		
		      "Contribution" shall mean any work of authorship, including
		      the original version of the Work and any modifications or additions
		      to that Work or Derivative Works thereof, that is intentionally
		      submitted to Licensor for inclusion in the Work by the copyright owner
		      or by an individual or Legal Entity authorized to submit on behalf of
		      the copyright owner. For the purposes of this definition, "submitted"
		      means any form of electronic, verbal, or written communication sent
		      to the Licensor or its representatives, including but not limited to
		      communication on electronic mailing lists, source code control systems,
		      and issue tracking systems that are managed by, or on behalf of, the
		      Licensor for the purpose of discussing and improving the Work, but
		      excluding communication that is conspicuously marked or otherwise
		      designated in writing by the copyright owner as "Not a Contribution."
		
		      "Contributor" shall mean Licensor and any individual or Legal Entity
		      on behalf of whom a Contribution has been received by Licensor and
		      subsequently incorporated within the Work.
		
		   2. Grant of Copyright License. Subject to the terms and conditions of
		      this License, each Contributor hereby grants to You a perpetual,
		      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
		      copyright license to reproduce, prepare Derivative Works of,
		      publicly display, publicly perform, sublicense, and distribute the
		      Work and such Derivative Works in Source or Object form.
		
		   3. Grant of Patent License. Subject to the terms and conditions of
		      this License, each Contributor hereby grants to You a perpetual,
		      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
		      (except as stated in this section) patent license to make, have made,
		      use, offer to sell, sell, import, and otherwise transfer the Work,
		      where such license applies only to those patent claims licensable
		      by such Contributor that are necessarily infringed by their
		      Contribution(s) alone or by combination of their Contribution(s)
		      with the Work to which such Contribution(s) was submitted. If You
		      institute patent litigation against any entity (including a
		      cross-claim or counterclaim in a lawsuit) alleging that the Work
		      or a Contribution incorporated within the Work constitutes direct
		      or contributory patent infringement, then any patent licenses
		      granted to You under this License for that Work shall terminate
		      as of the date such litigation is filed.
		
		   4. Redistribution. You may reproduce and distribute copies of the
		      Work or Derivative Works thereof in any medium, with or without
		      modifications, and in Source or Object form, provided that You
		      meet the following conditions:
		
		      (a) You must give any other recipients of the Work or
		          Derivative Works a copy of this License; and
		
		      (b) You must cause any modified files to carry prominent notices
		          stating that You changed the files; and
		
		      (c) You must retain, in the Source form of any Derivative Works
		          that You distribute, all copyright, patent, trademark, and
		          attribution notices from the Source form of the Work,
		          excluding those notices that do not pertain to any part of
		          the Derivative Works; and
		
		      (d) If the Work includes a "NOTICE" text file as part of its
		          distribution, then any Derivative Works that You distribute must
		          include a readable copy of the attribution notices contained
		          within such NOTICE file, excluding those notices that do not
		          pertain to any part of the Derivative Works, in at least one
		          of the following places: within a NOTICE text file distributed
		          as part of the Derivative Works; within the Source form or
		          documentation, if provided along with the Derivative Works; or,
		          within a display generated by the Derivative Works, if and
		          wherever such third-party notices normally appear. The contents
		          of the NOTICE file are for informational purposes only and
		          do not modify the License. You may add Your own attribution
		          notices within Derivative Works that You distribute, alongside
		          or as an addendum to the NOTICE text from the Work, provided
		          that such additional attribution notices cannot be construed
		          as modifying the License.
		
		      You may add Your own copyright statement to Your modifications and
		      may provide additional or different license terms and conditions
		      for use, reproduction, or distribution of Your modifications, or
		      for any such Derivative Works as a whole, provided Your use,
		      reproduction, and distribution of the Work otherwise complies with
		      the conditions stated in this License.
		
		   5. Submission of Contributions. Unless You explicitly state otherwise,
		      any Contribution intentionally submitted for inclusion in the Work
		      by You to the Licensor shall be under the terms and conditions of
		      this License, without any additional terms or conditions.
		      Notwithstanding the above, nothing herein shall supersede or modify
		      the terms of any separate license agreement you may have executed
		      with Licensor regarding such Contributions.
		
		   6. Trademarks. This License does not grant permission to use the trade
		      names, trademarks, service marks, or product names of the Licensor,
		      except as required for reasonable and customary use in describing the
		      origin of the Work and reproducing the content of the NOTICE file.
		
		   7. Disclaimer of Warranty. Unless required by applicable law or
		      agreed to in writing, Licensor provides the Work (and each
		      Contributor provides its Contributions) on an "AS IS" BASIS,
		      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
		      implied, including, without limitation, any warranties or conditions
		      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
		      PARTICULAR PURPOSE. You are solely responsible for determining the
		      appropriateness of using or redistributing the Work and assume any
		      risks associated with Your exercise of permissions under this License.
		
		   8. Limitation of Liability. In no event and under no legal theory,
		      whether in tort (including negligence), contract, or otherwise,
		      unless required by applicable law (such as deliberate and grossly
		      negligent acts) or agreed to in writing, shall any Contributor be
		      liable to You for damages, including any direct, indirect, special,
		      incidental, or consequential damages of any character arising as a
		      result of this License or out of the use or inability to use the
		      Work (including but not limited to damages for loss of goodwill,
		      work stoppage, computer failure or malfunction, or any and all
		      other commercial damages or losses), even if such Contributor
		      has been advised of the possibility of such damages.
		
		   9. Accepting Warranty or Additional Liability. While redistributing
		      the Work or Derivative Works thereof, You may choose to offer,
		      and charge a fee for, acceptance of support, warranty, indemnity,
		      or other liability obligations and/or rights consistent with this
		      License. However, in accepting such obligations, You may act only
		      on Your own behalf and on Your sole responsibility, not on behalf
		      of any other Contributor, and only if You agree to indemnify,
		      defend, and hold each Contributor harmless for any liability
		      incurred by, or claims asserted against, such Contributor by reason
		      of your accepting any such warranty or additional liability.
		
		   END OF TERMS AND CONDITIONS
		
		   APPENDIX: How to apply the Apache License to your work.
		
		      To apply the Apache License to your work, attach the following
		      boilerplate notice, with the fields enclosed by brackets "[]"
		      replaced with your own identifying information. (Don't include
		      the brackets!)  The text should be enclosed in the appropriate
		      comment syntax for the file format. We also recommend that a
		      file or class name and description of purpose be included on the
		      same "printed page" as the copyright notice for easier
		      identification within third-party archives.
		
		   Copyright 2019 Georgios Poulopoulos
		
		   Licensed under the Apache License, Version 2.0 (the "License");
		   you may not use this file except in compliance with the License.
		   You may obtain a copy of the License at
		
		       http://www.apache.org/licenses/LICENSE-2.0
		
		   Unless required by applicable law or agreed to in writing, software
		   distributed under the License is distributed on an "AS IS" BASIS,
		   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
		   See the License for the specific language governing permissions and
		limitations under the License.
		
	#tag EndNote


	#tag Property, Flags = &h1
		#tag Note
			this is used by the generateUUID method.
			if you replace the UUID mechanism with something else, you can safely remove this property
		#tag EndNote
		Protected localDB As SQLiteDatabase
	#tag EndProperty


	#tag Constant, Name = empty, Type = String, Dynamic = False, Default = \"", Scope = Private
	#tag EndConstant

	#tag Constant, Name = fragmentSize, Type = Double, Dynamic = False, Default = \"8", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LimnieProjectURL, Type = Text, Dynamic = False, Default = \"https://github.com/gregorplop/Limnie", Scope = Public
	#tag EndConstant

	#tag Constant, Name = LimnieVersion, Type = Double, Dynamic = False, Default = \"0.8", Scope = Public
	#tag EndConstant

	#tag Constant, Name = MByte, Type = Double, Dynamic = False, Default = \"1048576", Scope = Private
	#tag EndConstant

	#tag Constant, Name = mediumFilename, Type = String, Dynamic = False, Default = \"Limnie_medium", Scope = Private
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
End Module
#tag EndModule
