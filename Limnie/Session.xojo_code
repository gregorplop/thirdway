#tag Class
Protected Class Session
	#tag Method, Flags = &h0
		Sub Close()
		  Destructor
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub closeActiveMedium()
		  if IsNull(activeMedium) = false then
		    activeMedium.Close
		    activeMedium = nil
		  end if
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(inputVFS as Limnie.VFS)
		  ErrorMsg = empty
		  
		  if inputVFS = nil then 
		    ErrorMsg = "Invalid VFS object!"
		    return
		  end if
		  
		  if inputVFS.file = nil then 
		    ErrorMsg = "Invalid VFS file!"
		    return
		  end if
		  
		  if inputVFS.file.Exists = false then 
		    ErrorMsg = "VFS file " + inputVFS.file.NativePath + " does not exist!"
		    return
		  end if
		  
		  if inputVFS.file.Directory = true then 
		    ErrorMsg = "VFS file " + inputVFS.file.NativePath + " is really a directory!"
		    Return
		  end if
		  
		  if inputVFS.file.IsWriteable = false then 
		    ErrorMsg = "VFS file " + inputVFS.file.NativePath + " is not writeable!"
		    Return
		  end if
		  
		  if inputVFS.file.IsReadable = false then 
		    ErrorMsg = "VFS file " + inputVFS.file.NativePath + " is not readable!"
		    Return
		  end if
		  
		  activeVFS = new SQLiteDatabase
		  activeVFS.DatabaseFile = inputVFS.file
		  
		  if inputVFS.password <> empty then
		    activeVFS.EncryptionKey = preparePassword(inputVFS.password)
		  end if
		  
		  if activeVFS.Connect = false then
		    ErrorMsg = "Error connecting to " + inputVFS.file.name + " : " + activeVFS.ErrorMessage
		    activeVFS = nil
		    Return
		  end if
		  
		  activeVFS.MultiUser = true  // enable WAL, remember to never mount the database via a network file system!
		  
		  dim testvalue as variant // let's run some tests to see if it's a valid Limnie
		  
		  testvalue = getVFSparameter("name")
		  if testvalue = nil then 
		    ErrorMsg = "Loaded file is not a valid VFS: " + ErrorMsg
		    activeVFS.Close
		    activeVFS = nil
		    Return
		  end if
		  if testvalue.StringValue = empty then 
		    ErrorMsg = "Loaded file is not a valid VFS: No VFS name!"
		    activeVFS.Close
		    activeVFS = nil
		    return
		  end if
		  
		  testvalue = getVFSparameter("version")
		  if testvalue = nil then 
		    ErrorMsg = "Loaded file is not a valid VFS: " + ErrorMsg
		    activeVFS.Close
		    activeVFS = nil
		    return
		  end if
		  if testvalue.StringValue = empty then 
		    ErrorMsg = "Loaded file is not a valid VFS: No VFS version!"
		    activeVFS.Close
		    activeVFS = nil
		    Return
		  end if
		  
		  testvalue = getVFSparameter("initstamp")
		  if testvalue = nil then 
		    ErrorMsg = "Loaded file is not a valid VFS: " + ErrorMsg
		    activeVFS.Close
		    activeVFS = nil
		    return
		  end if
		  if testvalue.StringValue = empty then 
		    ErrorMsg = "Loaded file is not a valid VFS: No init date!"
		    activeVFS.Close
		    activeVFS = nil
		    return
		  end if
		  
		  testvalue = getVFSparameter("hostname")
		  if testvalue = nil then 
		    ErrorMsg = "Loaded file is not a valid VFS: " + ErrorMsg
		    activeVFS.Close
		    activeVFS = nil
		    return
		  end if
		  if testvalue.StringValue <> hostname then
		    ErrorMsg = "Loaded VFS has been created on hostname " + testvalue.StringValue + " and it is being mounted on " + hostname + ". This cannot be allowed!"
		    activeVFS.Close
		    activeVFS = nil
		    return
		  end if
		  
		  // all ok
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function createDocument(source as Readable, poolname as string, metadatum as String, yielding as Boolean, optional PlainPasswd as Variant = nil) As Limnie.Document
		  if IsNull(source) then return new Limnie.Document("New document source is invalid!")
		  dim poolDetails as Limnie.Pool = getPoolDetails(poolname)
		  if poolDetails.error then return new Limnie.Document("New document pool could not be opened: " + poolDetails.errorMessage)
		  
		  dim Media(-1) as Limnie.Medium  
		  dim newDocument as new Limnie.Document // log of new records in pool & medium tables for the case of failure and rollback
		  dim newFragment as Limnie.Fragment // log of new records in pool & medium tables for the case of failure and rollback
		  dim fragmentData as string
		  dim mediumPickTimeout as integer
		  dim PickedMedium as integer
		  dim setActiveMediumOK as Limnie.Medium
		  dim md5calculator as new MD5Digest
		  dim uuid as String = generateUUID
		  dim firstObjidx as Int64 = -1
		  dim newlyCreatedObjidx as int64
		  dim newPoolCatalogueRecord as DatabaseRecord
		  dim newMediumRecord as DatabaseRecord
		  dim creationDate as new date
		  dim finalHash as string = "pending"
		  dim objidxs(-1) as string
		  dim totalDocumentSize as Int64 = 0
		  
		  if uuid = empty then Return new Limnie.Document("Error creating document: Could not generate UUID")
		  
		  newDocument.pool = poolname
		  newDocument.uuid = uuid
		  
		  do until source.EOF
		    
		    fragmentData = source.Read(fragmentSize * MByte)  // get a fragment
		    
		    if source.ReadError then  // crap, we have to rollback
		      dim rollbackOK as String = rollbackPushData(newDocument , PlainPasswd)
		      Return new Limnie.Document("Read error while creating new document: Attempted Rollback: " + if(rollbackOK = empty , "OK" , rollbackOK))
		    end if
		    
		    if yielding then app.YieldToNextThread  // =============try to make things more smooth in desktop apps, not sure if it's going to work :p =====================
		    
		    // we need to decide which medium to write it to
		    mediumPickTimeout = 10  // try this number of times
		    do
		      Media = getMediaDetails("pool = '" + poolname + "' AND open = 'true'" , "idx ASC")  // get all open media for pool
		      if Media.Ubound = 0 and Media(0).errorCode = -1 then   // getMediaDetails failed
		        dim rollbackOK as String = rollbackPushData(newDocument , PlainPasswd)
		        Return new Limnie.Document("Media survey error while creating new document: " + Media(0).errorMessage + " : Attempted Rollback: " + if(rollbackOK = empty , "OK" , rollbackOK))
		      end if
		      
		      PickedMedium = pickSuitableMedium(Media , fragmentData.LenB) // try to pick a medium 
		      
		      if PickedMedium = -1 then 
		        dim createNextMediumOK as Limnie.Medium = createNextMedium(poolname , true , PlainPasswd)  // this is pool auto-expansion
		        
		        select case createNextMediumOK.errorCode
		        case 1  // infrastructure error
		          dim rollbackOK as String = rollbackPushData(newDocument , PlainPasswd)
		          Return new Limnie.Document("Could not auto-expand pool: " + createNextMediumOK.errorMessage + " : Attempted Rollback: " + if(rollbackOK = empty , "OK" , rollbackOK))
		        case 2  // maintenance lock on this pool, something's cooking, wait a bit...
		          #if TargetConsole or TargetWeb then
		            dim startMoment as Integer = date(new date).TotalSeconds
		            while date(new date).TotalSeconds - startMoment < 2
		              app.DoEvents  // it might be a server app with everything running on the main thread; be polite and don't block other people's events
		            wend
		          #Elseif TargetDesktop
		            if yielding then app.YieldToNextThread  // =============try to make things more smooth in desktop apps, not sure if it's going to work :p =====================
		            app.SleepCurrentThread(2000)  // we can't use doevents here, just sleep it off
		          #endif
		          mediumPickTimeout = mediumPickTimeout - 1
		        end select
		        
		        if mediumPickTimeout = 0 then  // we've waited more than enough for a new medium to be created, something has gone wrong, abort
		          dim rollbackOK as String = rollbackPushData(newDocument , PlainPasswd)
		          Return new Limnie.Document("Timeout while waiting for pool to auto-expand: Rollback: " + if(rollbackOK = empty , "OK" , rollbackOK))
		        end if
		      end if
		    loop until PickedMedium > 0
		    
		    setActiveMediumOK = setActiveMedium(poolname , PickedMedium , PlainPasswd)
		    if setActiveMediumOK.error = true then
		      dim rollbackOK as String = rollbackPushData(newDocument , PlainPasswd)
		      Return new Limnie.Document("Error opening medium " + str(PickedMedium) + " : " + setActiveMediumOK.errorMessage + " : Attempted Rollback: " + if(rollbackOK = empty , "OK" , rollbackOK))
		    end if
		    
		    if yielding then app.YieldToNextThread  // =============try to make things more smooth in desktop apps, not sure if it's going to work :p ====================
		    
		    md5calculator.Process(fragmentData)
		    
		    newPoolCatalogueRecord = new DatabaseRecord
		    newPoolCatalogueRecord.IntegerColumn("mediumidx") = PickedMedium
		    newPoolCatalogueRecord.Int64Column("size") = fragmentData.LenB
		    newPoolCatalogueRecord.DateColumn("creationstamp") = creationDate
		    newPoolCatalogueRecord.DateColumn("lastchange") = creationDate
		    newPoolCatalogueRecord.BooleanColumn("deleted") = false
		    newPoolCatalogueRecord.BooleanColumn("locked") = true
		    newPoolCatalogueRecord.Column("uuid") = uuid
		    if  metadatum.Trim <> empty then newPoolCatalogueRecord.Column("metadatum") = metadatum.Trim
		    
		    if firstObjidx = -1 and source.EOF = true then firstObjidx = 0  // this is the first and only fragment
		    if source.EOF = true then 
		      finalHash = EncodeHex(md5calculator.Value)  // this is the final fragment
		      newDocument.hash = finalHash
		    end if
		    
		    newPoolCatalogueRecord.Int64Column("firstpart") = firstObjidx
		    newPoolCatalogueRecord.Column("hash") = finalHash
		    
		    activeVFS.InsertRecord(poolname , newPoolCatalogueRecord)  // create the record in the pool catalogue
		    if activeVFS.Error = true then 
		      dim rollbackOK as String = rollbackPushData(newDocument , PlainPasswd)
		      Return new Limnie.Document("Database error while creating pool catalogue records: " + activeVFS.ErrorMessage + " : Attempted Rollback: " + if(rollbackOK = empty , "OK" , rollbackOK))
		    end if
		    
		    newlyCreatedObjidx = activeVFS.LastRowID
		    
		    newFragment = new Limnie.Fragment
		    newFragment.objidx = newlyCreatedObjidx  // necessary for rollback
		    newFragment.mediumidx = PickedMedium     // necessary for rollback
		    newFragment.mediumFile = activeMedium.DatabaseFile  // only because setActiveMedium has preceeded this
		    newFragment.size = fragmentData.LenB
		    newFragment.locked = true
		    newDocument.fragments.Append newFragment
		    
		    // some other Document-wide properties that are clear at this point
		    newDocument.creationStamp = creationDate
		    newDocument.lastChangeStamp = creationDate
		    newDocument.metadatum = metadatum.Trim
		    
		    
		    if firstObjidx = -1 then   // first part of a fragmented document has just been stored - it's missing the correct firstpart field value
		      newDocument.fragmented = true
		      firstObjidx = newlyCreatedObjidx
		      activeVFS.SQLExecute("UPDATE " + poolname + " SET firstpart = " + str(firstObjidx) + " WHERE objidx = " + str(firstObjidx))  // update the firstpart field of the first record of a fragmented document
		      if activeVFS.Error = true then 
		        dim rollbackOK as String = rollbackPushData(newDocument , PlainPasswd)
		        Return new Limnie.Document("Database error while updating pool catalogue records: " + activeVFS.ErrorMessage + " : Attempted Rollback: " + if(rollbackOK = empty , "OK" , rollbackOK))
		      end if
		    end if
		    
		    
		    if firstObjidx > 0 and source.EOF = true then  // the last part of a fragmented document, all past records are missing the correct hash
		      activeVFS.SQLExecute("UPDATE " + poolname + " SET hash = '" + finalHash + "' WHERE firstpart = " + str(firstObjidx))
		      if activeVFS.Error = true then
		        dim rollbackOK as String = rollbackPushData(newDocument , PlainPasswd)
		        Return new Limnie.Document("Error updating fragmented document hash: " + activeVFS.ErrorMessage + " : Attempted Rollback: " + if(rollbackOK = empty , "OK" , rollbackOK))
		      end if
		    end if
		    
		    // at this point we have created/updated entries in the pool master table
		    // we are ready to write content into the selected medium
		    if yielding then app.YieldToNextThread  // =============try to make things more smooth in desktop apps, not sure if it's going to work :p ====================
		    
		    newMediumRecord = new DatabaseRecord
		    newMediumRecord.Int64Column("objidx") = newlyCreatedObjidx
		    newMediumRecord.Int64Column("firstpart") = firstObjidx
		    newMediumRecord.BlobColumn("content") = fragmentData
		    // the correct medium has already been opened
		    activeMedium.InsertRecord("content" , newMediumRecord)
		    
		    if activeMedium.Error = true then
		      dim rollbackOK as String = rollbackPushData(newDocument , PlainPasswd)
		      Return new Limnie.Document("Error writing fragmented content to active medium: " + activeMedium.ErrorMessage + " : Attempted Rollback: " + if(rollbackOK = empty , "OK" , rollbackOK))
		    end if
		    
		  loop  // get next fragment if any
		  
		  // we need to unlock newly created fragment records
		  
		  for i as integer = 0 to newDocument.fragments.Ubound  // this is just to have a simpler update statement
		    objidxs.Append str(newDocument.fragments(i).objidx)
		    newDocument.fragments(i).locked = false
		    totalDocumentSize = totalDocumentSize + newDocument.fragments(i).size
		  next i
		  
		  activeVFS.SQLExecute("UPDATE " + poolname + " SET locked = 'false' WHERE objidx IN (" + join(objidxs , ",") + ")")
		  if activeVFS.Error = true then 
		    dim rollbackOK as String = rollbackPushData(newDocument , PlainPasswd)
		    Return new Limnie.Document("Error unlocking pool catalogue entries: " + activeVFS.ErrorMessage + " : Attempted Rollback: " + if(rollbackOK = empty , "OK" , rollbackOK))
		  end if
		  
		  newDocument.objidx = newDocument.fragments(0).objidx
		  newDocument.deleted = false
		  newDocument.size = totalDocumentSize
		  newDocument.error = false // of course!
		  
		  Return newDocument
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function createNewPool(newPool as Limnie.Pool) As Limnie.Pool
		  if IsNull(activeVFS) then return new Limnie.Pool("Session is not active!")
		  if IsNull(newPool) then return new Limnie.Pool("New pool object is null")
		  
		  newPool.friendlyName = newPool.friendlyName.SuperTrim
		  newPool.comments = newPool.comments.SuperTrim
		  newPool.name = newPool.name.SuperTrim(true)
		  
		  newPool = initPool(newPool)
		  if newPool.error then Return newPool  // something went wrong creating the pool in the VFS: fail
		  
		  // at this point 3 things have completed successfully:
		  // 1. a table called newPool.name has been created
		  // 2. a record newPool.name has been inserted in the pools table
		  // 3. if a user has set a password, the pool-password pair has been added to the poolPasswords dictionary
		  
		  // we are going to create the first medium of the pool: we cannot have a pool without at least 1 medium,
		  // especially a password-pretected pool: the medium db is the only place where the password is applied and can be compared against: it exists nowhere else
		  
		  //dim poolInfo as Limnie.Pool = getPoolDetails(newPool.name)  // SHIT! I LOSE THE PASSWORD HERE
		  
		  dim saltedPassword as string 
		  saltedPassword = if(newPool.salt = empty , empty , preparePassword(newPool.password , newPool.salt))
		  
		  dim firstMedium as Limnie.Medium = initMedium(newPool.name , 1 , newPool.rootFolder , newPool.mediumThreshold , saltedPassword)
		  
		  if firstMedium.error then
		    dim rollbackOK as string = rollbackInitPool(newPool.name)
		    return new Limnie.Pool("Error creating first pool medium: " + firstMedium.errorMessage + if(rollbackOK = empty , " : Creation rollback OK" , rollbackOK))
		  end if
		  
		  newPool.mediaCount = 1  // we've already made one, let's not return an inaccurate piece of info!
		  
		  return newPool // success
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function createNextMedium(poolname as string, autoExpansion as Boolean, optional plainPasswd as Variant = nil) As Limnie.Medium
		  // autoExpansion = true means this is a Limnie internal request, not a user manually wanting to create the next Medium
		  // plainPasswd is the plaintext password if the pool is encrypted
		  
		  dim pooldetails as Limnie.Pool = getPoolDetails(poolname)
		  if pooldetails.error then return new Limnie.Medium("Error verifying pool: " + pooldetails.errorMessage)
		  
		  if pooldetails.autoExpand = False and autoExpansion = true then return new Limnie.Medium("This pool is not set to auto-expand!")
		  
		  dim poolLock as new Mutex(pooldetails.uuid)
		  if poolLock.TryEnter = false then Return new Limnie.Medium("Pool " + poolname + " locked for maintenance" , 2)  // error code 2 is to differentiate this failure from an infrastructure failure: it means TRY LATER, rather than IT BLEW UP, FORGET IT
		  // be careful of the pool lock: if the application crashes before releasing it, no other client will be able to add a medium until the lock has been manually reset!
		  
		  // at this point we have successfully locked the pool for maintenance
		  dim nextFreeID as integer = getFreeMediumID(poolname)
		  if nextFreeID < 0 then 
		    poolLock.Leave
		    return new Limnie.Medium("Error getting free medium ID: " + ErrorMsg)
		  end if
		  
		  // we have a free id and we know/hope nobody else is going to reserve it
		  
		  dim saltedPassword as String = empty
		  
		  if pooldetails.encrypted = true then  // the pool is configured to be encrypted; we need to find the password
		    
		    dim verifyOK as pair
		    
		    if plainPasswd.IsNull then // class user did not supply a password to the method
		      
		      poolLock.Leave
		      Return new Limnie.Medium("Password expected for encrypted pool but not provided!")
		      
		    else // class user did supply a password: we need to verify it
		      
		      if plainPasswd.Type <> Variant.TypeString then
		        poolLock.Leave
		        Return new Limnie.Medium("Supplied password not textual, error verifying!")
		      end if
		      
		      saltedPassword = preparePassword(plainPasswd.StringValue , pooldetails.salt)  
		      verifyOK = testPoolPassword(poolname , saltedPassword)
		      
		      select case verifyOK.Left.IntegerValue
		      case 0  // all ok
		        // nothing to do
		      case 1  // infrastructure failure
		        poolLock.Leave
		        return new Limnie.Medium("Error verifying password for creating next encrypted medium: " + verifyOK.Right.StringValue , 1)
		      case 2 // password mismatch (or db corruption, but we can't really tell the difference)
		        poolLock.Leave
		        Return new Limnie.Medium("Password not verified!" , 2)
		      else  // isn't supposed to happen
		        poolLock.Leave
		        Return new Limnie.Medium("Internal error!")
		      end select
		      
		      
		    end if
		  end if
		  
		  dim newMedium as Limnie.Medium = initMedium(poolname , nextFreeID , pooldetails.rootFolder , pooldetails.mediumThreshold , saltedPassword)
		  poolLock.Leave // release the pool maintenance lock
		  
		  return newMedium
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Destructor()
		  if isnull(activeMedium) = False then activeMedium.close
		  if isnull(activeVFS) = false then activeVFS.close
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function findPoolOfDocUUID(uuid as string) As Limnie.Document
		  // locates the pool of a document UUID by means of consequent queries following an "informed" Monte Carlo approach
		  // informed Monte Carlo meaning random pool selection but always last resulted pool is searched first
		  // if uuid is found in a pool then Limnie.Pool.name contains is 
		  // if it's not found but there was no error in the process, name is empty
		  
		  static lastPoolFound as String
		  
		  dim pools(-1) as String = getPoolNames
		  if ErrorMsg <> empty then return new Limnie.Document("Error surveying pools for document " + uuid + " : " + ErrorMsg)
		  if pools.Ubound < 0 then return new Limnie.Document("This Limnie contains no storage pools")
		  
		  dim lastPoolFoundIDX as Integer = pools.IndexOf(lastPoolFound)
		  if lastPoolFoundIDX >= 0 then
		    pools.Remove(lastPoolFoundIDX)
		    pools.Shuffle
		    pools.Insert(0 , lastPoolFound)
		  else  // pool has been removed since
		    lastPoolFound = empty
		    pools.Shuffle
		  end if
		  
		  dim rs as RecordSet
		  
		  dim output as new Limnie.Document
		  output.pool = empty // just making it excpicit that if uuid is not found in any pool then this is the return value
		  
		  for i as Integer = 0 to pools.Ubound
		    rs = activeVFS.SQLSelect("SELECT COUNT(uuid) FROM " + pools(i) + " WHERE uuid = " + uuid.sqlQuote)
		    if activeVFS.Error then return new Limnie.Document("Error looking for document UUID in pool: " + activeVFS.ErrorMessage)
		    if rs.IdxField(1).IntegerValue > 0 then
		      output.pool = pools(i)
		      return output
		    end if
		  next i
		  
		  Return output  // name = empty
		  
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function generateSalt() As string
		  Return EncodeHex(MD5(str(Microseconds)))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getDocumentDetails(poolname as string, id as string, optional IncludeDeleted as Boolean = False) As Limnie.Document
		  //the id can either be the objidx of the document or its uuid, the method recognizes it automatically
		  if isnull(activeVFS) = true then return new Limnie.Document("VFS database is no longer active")
		  
		  dim isUUID as Boolean
		  if IsNumeric(id) then isUUID = false else isUUID = true  // and if it's not a uuid then it's an objidx
		  
		  if isUUID then 
		    if validateUUID(id) = false then return new Limnie.Document("Requested document details of invalid UUID")
		  end if
		  
		  dim rs as RecordSet
		  dim query as String = "SELECT * FROM '" + poolname + "' WHERE "
		  
		  if isUUID then
		    query = query + "uuid = '" + id + "'"
		  else
		    query = query + "objidx = " + id
		  end if
		  
		  if IncludeDeleted then query = query + " AND deleted = 'true'"
		  query = query + " ORDER BY objidx ASC LIMIT 1"
		  
		  rs = activeVFS.SQLSelect(query)
		  
		  if activeVFS.Error then return new Limnie.Document("Error querying pool " + poolname + " for document ID " + id + " : " + activeVFS.ErrorMessage)
		  if rs.RecordCount = 0 then return new Limnie.Document("Document ID " + id + " does not exist in pool " + poolname)
		  
		  if isUUID = false then
		    if rs.Field("firstpart").IntegerValue <> 0 and rs.field("firstpart").StringValue <> id then
		      return new Limnie.Document("ID " + id + " is an intermediate fragment of document " + rs.Field("firstpart").StringValue + ". You normally should not know this value, check your application database consistency!")
		    end if
		  end if
		  
		  
		  dim output as new Limnie.Document
		  dim fragment as Limnie.Fragment
		  dim mediumInfo as new Limnie.Medium
		  
		  output.objidx = rs.Field("objidx").Int64Value
		  output.metadatum = rs.Field("metadatum").StringValue
		  output.creationStamp = rs.Field("creationstamp").DateValue
		  output.lastChangeStamp = rs.Field("lastchange").DateValue
		  output.deleted = rs.Field("deleted").BooleanValue
		  output.pool = poolname
		  output.hash = rs.Field("hash").StringValue
		  output.uuid = rs.Field("uuid").StringValue
		  
		  if rs.Field("firstpart").IntegerValue = 0 then  // document consists of 1 fragment
		    output.fragmented = false
		    fragment = new Limnie.Fragment
		    fragment.objidx = rs.Field("objidx").Int64Value
		    fragment.mediumidx = rs.Field("mediumidx").IntegerValue
		    fragment.size = rs.Field("size").Int64Value
		    output.size = fragment.size
		    fragment.locked = rs.Field("locked").BooleanValue
		    
		    mediumInfo = getMediumDetails(poolname , fragment.mediumidx)
		    if mediumInfo.error = true then return new Limnie.Document("Error getting medium info: " + mediumInfo.errorMessage)
		    fragment.mediumFile = mediumInfo.folder.Child(mediumFilename)
		    
		    output.fragments.Append fragment
		    
		  else  // document consists of multiple fragments
		    
		    output.fragmented = true
		    
		    rs = activeVFS.SQLSelect("SELECT * FROM " + poolname + " WHERE firstpart = " + str(output.objidx) + " ORDER BY objidx ASC")
		    if activeVFS.Error = true then return new Limnie.Document("Error while querying for fragments : " + activeVFS.ErrorMessage)
		    if rs.RecordCount = 0 then return new Limnie.Document("No fragments found for fragmented document " + str(id))
		    dim documentSize as Int64 = 0
		    
		    while not rs.EOF
		      fragment = new Limnie.Fragment
		      fragment.objidx = rs.Field("objidx").Int64Value
		      fragment.mediumidx = rs.Field("mediumidx").IntegerValue
		      fragment.size = rs.Field("size").Int64Value
		      documentSize = documentSize + fragment.size
		      fragment.locked = rs.Field("locked").BooleanValue
		      
		      if mediumInfo.pool = poolname and mediumInfo.idx = fragment.mediumidx then  // fragment belongs to the last inquired medium
		        fragment.mediumFile = mediumInfo.folder.Child(mediumFilename)
		      else  //  we need to get medium details
		        mediumInfo = getMediumDetails(poolname , fragment.mediumidx)
		        if mediumInfo.error = true then return new Limnie.Document("Error getting medium info: " + mediumInfo.errorMessage)
		        fragment.mediumFile = mediumInfo.folder.Child(mediumFilename)
		      end if
		      
		      output.fragments.Append fragment
		      rs.MoveNext
		    wend
		    output.size = documentSize
		    
		  end if
		  
		  return output
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function getFreeMediumID(poolname as string) As integer
		  ErrorMsg = empty
		  
		  dim rs as RecordSet = activeVFS.SQLSelect("SELECT idx FROM media WHERE pool = '" + poolname + "' ORDER BY idx ASC")
		  
		  if activeVFS.Error = true then 
		    ErrorMsg = "Database error while looking for a free medium ID: " + activeVFS.ErrorMessage
		    return -1
		  end if
		  
		  if rs.RecordCount = 0 then
		    ErrorMsg = "Could not find any media for pool " + poolname
		    Return -1
		  end if
		  
		  dim counter as integer = 1
		  while not rs.EOF
		    if rs.IdxField(1).IntegerValue <> counter then exit while
		    counter = counter + 1
		    rs.MoveNext
		  wend
		  
		  return counter
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getLastError() As string
		  return ErrorMsg
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getMediaDetails(WHERE as String, ORDERBY as string) As Limnie.Medium()
		  // for infrastructure error method return one element on error state with error code = -1
		  dim output(-1) as Limnie.Medium
		  dim currentMedium as Limnie.Medium
		  
		  if IsNull(activeVFS) then Return Array(new Limnie.Medium("VFS not initialized!" , -1))
		  
		  if WHERE.trim = empty then WHERE = "TRUE"
		  if ORDERBY.trim = empty then ORDERBY = "pool , idx ASC"
		  
		  dim query as string = "SELECT * FROM media WHERE " + WHERE + " ORDER BY " + ORDERBY
		  
		  dim rs as RecordSet = activeVFS.SQLSelect(query)
		  if activeVFS.Error = true then Return Array(new Limnie.Medium("Error surveying media files: " + activeVFS.ErrorMessage , -1))
		  
		  dim ErrorMessage as string
		  
		  while not rs.EOF
		    
		    currentMedium = getMediumDetails(rs.Field("pool").StringValue , rs.Field("idx").IntegerValue)
		    
		    if currentMedium.error = true then
		      ErrorMessage = currentMedium.errorMessage
		      currentMedium = new Limnie.Medium(ErrorMessage)
		      currentMedium.idx = rs.Field("idx").IntegerValue
		      currentMedium.pool = rs.Field("pool").StringValue
		      currentMedium.uuid = rs.Field("uuid").StringValue
		    end if
		    
		    output.Append currentMedium
		    rs.MoveNext
		  wend
		  
		  return output
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getMediumDetails(poolname as string, mediumID as integer) As Limnie.Medium
		  if activeVFS = nil then return new Limnie.Medium("VFS not initialized!")
		  
		  dim rs as RecordSet = activeVFS.SQLSelect("SELECT * FROM media WHERE pool = '" + poolname + "' AND idx = " + str(mediumID))
		  if activeVFS.Error = true then return new Limnie.Medium("Error querying for medium: " + activeVFS.ErrorMessage)
		  if rs.RecordCount <> 1 then return new Limnie.Medium("Invalid medium record count: " + str(rs.RecordCount))
		  
		  dim output as Limnie.Medium = new Limnie.Medium
		  
		  output.pool = rs.Field("pool").StringValue
		  output.idx = rs.Field("idx").IntegerValue
		  
		  output.folder = GetFolderItem(rs.Field("folder").StringValue)
		  if output.folder = nil then return new Limnie.Medium("Folder path " + rs.Field("folder").StringValue + " does not exist!")
		  if output.folder.Exists = false then return new Limnie.Medium("Folder " + rs.Field("folder").StringValue + " does not exist!")
		  
		  output.file = output.folder.Child(mediumFilename)
		  if output.file.Exists = false then return new Limnie.Medium("Medium file in " + rs.Field("folder").StringValue + " does not exist!")
		  
		  output.threshold = rs.Field("threshold").IntegerValue
		  output.initStamp = rs.Field("initstamp").DateValue
		  output.open = rs.Field("open").BooleanValue
		  output.uuid = rs.Field("uuid").StringValue
		  
		  dim shm_filename as String = mediumFilename + "-shm"
		  dim wal_filename as string = mediumFilename + "-wal"
		  output.mounted = output.folder.Child(shm_filename).Exists and output.folder.Child(wal_filename).Exists  // this is a global metric, ie it show if medium has been mounted by *ANY* application running on the server
		  
		  output.size = output.file.Length
		  
		  dim maxBytesize as Int64 = output.threshold * MByte
		  output.utilization = Round((output.size * 100) / maxBytesize)
		  
		  
		  return output
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getPoolDetails(poolname as string, optional getMediaCount as Boolean = false) As Limnie.Pool
		  if activeVFS = nil then return new Limnie.Pool("Error getting pool details: VFS not initialized")
		  
		  dim rs as RecordSet = activeVFS.SQLSelect("SELECT * FROM pools WHERE name = '" + poolname + "'")
		  
		  if activeVFS.Error = true then return new Limnie.Pool("Error getting pool details: " + activeVFS.ErrorMessage)
		  if rs.RecordCount <> 1 then return new Limnie.Pool("Error getting pool details: Invalid pool record count: " + str(rs.RecordCount))
		  
		  dim output as new Limnie.Pool
		  
		  output.name = rs.Field("name").StringValue
		  output.friendlyName = rs.Field("friendlyname").StringValue
		  output.comments = rs.Field("comments").StringValue
		  output.rootFolder = GetFolderItem(rs.Field("rootfolder").StringValue)
		  output.mediumThreshold = rs.Field("sizelimit").IntegerValue
		  output.initStamp = rs.Field("initstamp").StringValue
		  output.autoExpand = rs.Field("autoexpand").BooleanValue
		  output.uuid = rs.Field("uuid").StringValue
		  output.salt = rs.Field("salt").StringValue
		  
		  if output.salt = empty then
		    output.encrypted = false
		  else
		    output.encrypted = true
		  end if
		  
		  if getMediaCount = true then
		    rs = activeVFS.SQLSelect("SELECT COUNT(*) FROM media WHERE pool = '" + poolname + "'")
		    if activeVFS.Error then 
		      output.mediaCount = -1
		    else
		      output.mediaCount = rs.IdxField(1).IntegerValue
		    end if
		  end if
		  
		  return output
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getPoolNames() As string()
		  dim output(-1) as String
		  ErrorMsg = empty
		  
		  if activeVFS = nil then
		    ErrorMsg = "Error getting pool names: VFS not initialized!"
		    return output
		  end if
		  
		  dim rs as RecordSet = activeVFS.SQLSelect("SELECT name FROM pools ORDER BY name ASC")
		  if activeVFS.Error = true then
		    ErrorMsg = activeVFS.ErrorMessage
		    return output
		  end if
		  
		  while not rs.EOF
		    output.Append rs.Field("name").StringValue
		    rs.MoveNext
		  wend
		  
		  return output
		  
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getPoolNames_Encrypted() As string()
		  dim output(-1) as String
		  ErrorMsg = empty
		  
		  if activeVFS = nil then
		    ErrorMsg = "Error getting pool names: VFS not initialized!"
		    return output
		  end if
		  
		  dim rs as RecordSet = activeVFS.SQLSelect("SELECT name FROM pools WHERE salt IS NOT NULL ORDER BY name ASC")
		  
		  if activeVFS.Error = true then
		    ErrorMsg = activeVFS.ErrorMessage
		    return output
		  end if
		  
		  while not rs.EOF
		    output.Append rs.Field("name").StringValue
		    rs.MoveNext
		  wend
		  
		  return output
		  
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function getVFSdetails() As Limnie.VFS
		  if activeVFS = nil then return new Limnie.VFS("VFS not initialized")
		  
		  dim rs as RecordSet = activeVFS.SQLSelect("SELECT * FROM vfs")
		  if activeVFS.Error = true then return new Limnie.VFS("Error getting VFS details: " + activeVFS.ErrorMessage)
		  
		  dim output as new Limnie.VFS
		  
		  while not rs.EOF
		    
		    select case rs.Field("key").StringValue
		    case "name"
		      output.name = rs.Field("value1").StringValue
		    case "friendlyname"
		      output.friendlyName = rs.Field("value1").StringValue
		    case "version"
		      output.version = rs.Field("value1").StringValue
		    case "initstamp"
		      output.initStamp = rs.Field("value1").DateValue
		    case "description"
		      output.description = rs.Field("value1").StringValue
		    case "uuid"
		      output.uuid = rs.Field("value1").StringValue
		    case "hostname"
		      output.hostname = rs.Field("value1").StringValue
		    end select
		    
		    rs.MoveNext
		  wend
		  
		  return output
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function getVFSparameter(parameter as string) As variant
		  ErrorMsg = empty
		  
		  if parameter.Trim = empty then
		    ErrorMsg = "Error reading VFS parameter: Parameter name is empty!"
		    return nil
		  end if
		  
		  if activeVFS = nil then 
		    ErrorMsg = "Error reading VFS parameter: VFS is no longer open!"
		    return nil
		  end if
		  
		  dim rs as RecordSet = activeVFS.SQLSelect("SELECT * FROM vfs WHERE key = '" + parameter + "'")
		  
		  if activeVFS.Error = true then 
		    ErrorMsg = "Error reading VFS parameter: Database error: " + activeVFS.ErrorMessage 
		    return nil
		  end if
		  
		  if rs.RecordCount = 0 then
		    ErrorMsg = "Error reading VFS parameter: No parameter <" + parameter + "> found!"
		    return nil
		  end if
		  
		  return rs.Field("value1").StringValue
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function initMedium(poolname as string, mediumID as integer, rootfolder as FolderItem, threshold as Int64, password as string) As Limnie.Medium
		  if activeVFS = nil then return new Limnie.Medium("Active VFS is no longer valid")
		  
		  if getPoolNames.IndexOf(poolname) < 0 then return new Limnie.Medium("Pool <" + poolname + "> does not exist!")
		  if mediumID <= 0 then return new Limnie.Medium("Invalid medium ID!")
		  
		  dim mediuminfo as Limnie.Medium = getMediumDetails(poolname , mediumID)
		  if mediuminfo.error = false then return new Limnie.Medium("Medium " + str(mediumID) + " already exists!")
		  
		  if rootfolder = nil then return new Limnie.Medium("Invalid root path!")
		  if rootfolder.Exists = false then return new Limnie.Medium("Root folder does not exist!")
		  if rootfolder.Directory = False then return new Limnie.Medium("Root folder name is not a directory!")
		  
		  if threshold < 512 then return new Limnie.Medium("Size threshold is lower than 512 MB!")
		  
		  dim mediumFolder as FolderItem = rootfolder.Child(poolname.trim.Lowercase + "." + str(mediumID))
		  if mediumFolder.Exists = true then return new Limnie.Medium("<" + mediumFolder.NativePath + "> already exists!")
		  
		  mediumFolder.CreateAsFolder
		  if mediumFolder.LastErrorCode <> 0 then return new Limnie.Medium("<" + mediumFolder.NativePath + "> could not be created!")
		  if mediumFolder.IsWriteable = false then return new Limnie.Medium("<" + mediumFolder.NativePath + "> is not writeable!")
		  if mediumFolder.IsReadable = false then return new Limnie.Medium("<" + mediumFolder.NativePath + "> is  not readable!")
		  
		  dim vfsInfo as Limnie.VFS = getVFSdetails
		  if vfsInfo.error then return new Limnie.Medium("Error reading VFS details!")
		  
		  dim poolInfo as Limnie.Pool = getPoolDetails(poolname)
		  if poolInfo.error then return new Limnie.Medium("Error reading pool details!")
		  
		  dim uuid as String = generateUUID
		  if uuid = empty then return new Limnie.Medium("Could not generate UUID for new medium!")
		  
		  dim mediumTimestamp as new date
		  dim mediumDBfile as FolderItem = mediumFolder.Child(mediumFilename)
		  dim mediumDB as new SQLiteDatabase
		  mediumDB.DatabaseFile = mediumDBfile
		  
		  mediumDB.EncryptionKey = password // input password is as-provided: no verifications and cross-checks are made here
		  
		  #If DebugBuild then
		    System.DebugLog(CurrentMethodName + ":EncryptionKey = " + mediumDB.EncryptionKey + ".")
		  #Endif
		  
		  if mediumDB.CreateDatabaseFile = False then  // attempt to create the database file
		    mediumFolder.Delete
		    return new Limnie.Medium("Error creating medium content file: " + mediumDB.ErrorMessage)
		  end if
		  
		  // at this point we have the medium db file created
		  
		  dim statements(-1) as string
		  statements.Append "CREATE TABLE vfs (key TEXT UNIQUE , value1 TEXT)"
		  statements.Append "CREATE TABLE content (objidx INTEGER PRIMARY KEY , firstpart INTEGER NOT NULL , content BLOB)"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('vfsname' , '" + vfsInfo.name + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('vfsuuid' , '" + vfsInfo.uuid + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('vfsversion' , '" + vfsInfo.version + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('initstamp' , '" + mediumTimestamp.SQLDateTime + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('pool' , '" + poolname + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('pooluuid' , '" + poolInfo.uuid + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('idx' , '" + str(mediumID) + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('threshold' , '" + str(threshold) + "')"
		  statements.Append "INSERT INTO vfs (key , value1) VALUES ('uuid' , '" + uuid + "')"
		  
		  dim mediumInitOutcome(-1) as string = bulkSQLexecute(mediumDB , statements , false)
		  
		  if getNonEmptyElements(mediumInitOutcome).Ubound >= 0 then
		    dim ErroneusStatementIDs(-1) as integer = getNonEmptyElements(mediumInitOutcome)
		    dim mediumInitErrorMsg as string = "Error initializing medium: " + EndOfLine
		    for i as integer = 0 to ErroneusStatementIDs.Ubound
		      mediumInitErrorMsg = mediumInitErrorMsg + statements(ErroneusStatementIDs(i)) + " --> " + mediumInitOutcome(ErroneusStatementIDs(i)) + EndOfLine
		    next i
		    mediumDB.Close
		    mediumDBfile.Delete
		    mediumFolder.Delete
		    return new Limnie.Medium(mediumInitErrorMsg)
		  ElseIf mediumInitOutcome.Ubound < 0 then
		    mediumDB.Close
		    mediumDBfile.Delete
		    mediumFolder.Delete
		    return new Limnie.Medium("Error initializing medium: internal error")
		  end if
		  
		  // at this point the medium database file is ready
		  mediumDB.close
		  // all we have to do is declare it to the vfs database
		  
		  activeVFS.SQLExecute("INSERT INTO media (uuid , pool , idx , folder , threshold , initstamp , open) VALUES ('" + uuid + "' , '" + poolname + "' , " + str(mediumID) + " , '" + mediumFolder.NativePath + "' , " + str(threshold) + " , '" + mediumTimestamp.SQLDateTime + "' , 'true')")
		  if activeVFS.Error then
		    mediumDBfile.Delete
		    mediumFolder.Delete
		    return new Limnie.Medium("Error registering new medium: " + activeVFS.ErrorMessage)
		  end if
		  
		  // at this point everything supposedly went well, let's test it
		  dim newlyCreatedMedium as Limnie.Medium = getMediumDetails(poolname , mediumID)
		  if newlyCreatedMedium.error  then  // hm.. not really, rollback what we did
		    activeVFS.SQLExecute("DELETE FROM media WHERE uuid = '" + uuid + "'")
		    if activeVFS.Error = False then
		      mediumDBfile.Delete
		      mediumFolder.Delete
		    end if
		  end if
		  
		  Return newlyCreatedMedium
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function initPool(newPool as Limnie.Pool) As Limnie.Pool
		  if IsNull(newPool) = true then return new Limnie.Pool("New pool object is null")
		  if getPoolNames.IndexOf(newPool.name) >= 0 or ErrorMsg <> empty then return new Limnie.Pool("Error verifying eligibility for pool: " + ErrorMsg)
		  if newPool.friendlyName.Trim = empty then return new Limnie.Pool("Pool friendly name is empty")
		  if isnull(newPool.rootfolder) = true then return new Limnie.Pool("Pool root folder path is invalid")
		  if newPool.rootfolder.Exists = false then return new Limnie.Pool("Pool root folder does not exist")
		  if newPool.rootfolder.Directory = False then return new Limnie.Pool("Pool root folder name is not a directory")
		  if newPool.rootfolder.IsWriteable = false then return new Limnie.Pool("Pool root folder is not Writeable")
		  if newPool.rootfolder.IsReadable = false then return new Limnie.Pool("Pool root folder is not Readable")
		  if newPool.mediumThreshold < 512 then return new Limnie.Pool("Pool size threshold is lower than 512 MB")
		  if activeVFS = nil then return new Limnie.Pool("Error creating pool: Active VFS is no longer valid")
		  
		  dim statements(-1) as string
		  dim insert as string
		  
		  statements.Append "CREATE TABLE " + newPool.name + " (objidx INTEGER PRIMARY KEY , uuid TEXT , mediumidx INTEGER NOT NULL , firstpart INTEGER NOT NULL , metadatum TEXT , size INTEGER NOT NULL , hash TEXT NOT NULL , creationstamp DATETIME NOT NULL , lastchange DATETIME NOT NULL , deleted BOOLEAN NOT NULL , locked BOOLEAN NOT NULL)"
		  statements.Append "CREATE INDEX " + newPool.name + "_uuid ON " + newPool.name + "(uuid)"  // this will speed up global uuid searches when object count becomes too high
		  
		  dim uuid as String = generateUUID
		  if uuid = empty then return new Limnie.Pool("Error creating pool: Could not generate pool UUID")
		  
		  insert = "INSERT INTO pools (uuid , name , friendlyname , comments , rootfolder , sizelimit , initstamp , autoexpand , salt) VALUES ("
		  insert = insert + uuid.sqlQuote + ","
		  insert = insert + newPool.Name.sqlQuote + ","
		  insert = insert + newPool.friendlyName.sqlQuote + ","
		  insert = insert + newPool.comments.sqlQuote + ","
		  insert = insert + newPool.rootFolder.NativePath.sqlQuote + ","
		  insert = insert + str(newPool.mediumThreshold) + ","
		  insert = insert + date(new date).SQLDateTime.sqlQuote + ","
		  insert = insert + newPool.autoExpand.sqlQuote + ","
		  
		  dim salt as string = empty
		  
		  if newPool.password.Trim = empty then
		    insert = insert + " null )"
		  else // user has supplied a password - a salt will be created
		    salt = generateSalt
		    insert = insert + salt.sqlQuote + ")"
		  end if
		  
		  statements.Append insert
		  
		  dim poolInitOutcome(-1) as string = bulkSQLexecute(activeVFS , statements , true)
		  if getNonEmptyElements(poolInitOutcome).Ubound >= 0 then // error in statements
		    
		    dim ErroneusStatementIDs(-1) as integer = getNonEmptyElements(poolInitOutcome)
		    dim initErrorMsg as string = "Error creating pool: " + EndOfLine
		    for i as integer = 0 to ErroneusStatementIDs.Ubound
		      initErrorMsg = initErrorMsg + statements(ErroneusStatementIDs(i)) + " --> " + poolInitOutcome(ErroneusStatementIDs(i)) + EndOfLine
		    next i
		    
		    return new Limnie.Pool(initErrorMsg)
		    
		  ElseIf poolInitOutcome.Ubound < 0 then  // error in infrastructure
		    return new Limnie.Pool("Error creating pool: internal error")
		    
		  end if
		  
		  // store the password in the cache
		  if newPool.password.Trim <> empty then 
		    newPool.salt = salt   // and notice that at this point newPool.password is carrying the user-defined plaintext password
		  end if
		  
		  newPool.error = false
		  newPool.errorMessage = empty
		  
		  return newPool
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function pickSuitableMedium(Media() as Limnie.Medium, contentSize as int64) As integer
		  // returns -1 if no suitable medium found
		  dim freeSpaceInMedium as Int64
		  
		  for i as Integer = 0 to Media.Ubound  // go through all media for pool
		    
		    if Media(i) = nil then Continue for i
		    if Media(i).open = false then Continue for i // not interested in closed media --redundant if list only contains open media
		    
		    freeSpaceInMedium = Media(i).threshold * MByte - Media(i).file.Length
		    
		    if freeSpaceInMedium < 0 then Continue for i  // limit has been exceeded for some reason
		    if freeSpaceInMedium >= contentSize then return Media(i).idx
		    
		  next i
		  
		  return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function readDocument(target as Writeable, poolname as string, uuid as string, yielding as Boolean, optional PlainPasswd as Variant = nil) As Limnie.Document
		  if IsNull(target) then return new Limnie.Document("Invalid storage target when retrieving data from Limnie!")
		  if IsNull(activeVFS) then return new Limnie.Document("VFS has been disconnected!")
		  
		  if validateUUID(uuid) = False then return new Limnie.Document("Requested document UUID is invalid!")
		  
		  dim docInfo as Limnie.Document = getDocumentDetails(poolname , uuid)
		  if docInfo.error then return new Limnie.Document("Error retrieving document " + uuid + " : " + docInfo.errorMessage)
		  if docInfo.deleted then return new Limnie.Document("Document " + uuid + " deleted on " + docInfo.lastChangeStamp.SQLDateTime)
		  if docInfo.isLocked then return new Limnie.Document("Document " + uuid + " is locked")
		  
		  dim setMediumOK as Limnie.Medium
		  dim fragmentStream as SQLiteBlob
		  dim md5calculator as new MD5Digest
		  dim content as string
		  
		  for i as integer = 0 to docInfo.fragments.Ubound // go through all the fragments
		    
		    setMediumOK = setActiveMedium(poolname , docInfo.fragments(i).mediumidx , PlainPasswd) // it is the app's responsibility to know this is an encrypted pool and supply the password
		    if setMediumOK.error then Return new Limnie.Document("Error opening medium " + poolname + "." + str(docInfo.fragments(i).mediumidx) + " : " + getLastError)
		    
		    fragmentStream = activeMedium.OpenBlob("content" , "content" , docInfo.fragments(i).objidx , false)
		    if isnull(fragmentStream) then Return new Limnie.Document("Error opening fragment " + str(docInfo.fragments(i).objidx) + " on medium " + poolname + "." + str(docInfo.fragments(i).mediumidx))
		    
		    while not fragmentStream.EOF
		      // the read operation reads exactly one standard-sized fragment, so it theoretically wouldn't need to be in a while/wend loop
		      // however, this method allows the method to read from media whose max fragment size is different from what's mentioned in constant fragmentSize.
		      // this would be the result of major misconfiguration and/or tampering with media files, and yet, we can survive it.
		      
		      content = fragmentStream.Read(fragmentSize * MByte)
		      
		      if fragmentStream.ReadError then
		        fragmentStream.Close
		        Return new Limnie.Document("Error reading fragment " + str(docInfo.fragments(i).objidx) + " on medium " + poolname + "." + str(docInfo.fragments(i).mediumidx))
		      end if
		      
		      if yielding then app.YieldToNextThread
		      
		      target.Write(content)
		      
		      if target.WriteError then
		        fragmentStream.Close
		        Return new Limnie.Document("Error writing fragment " + str(docInfo.fragments(i).objidx) + " on medium " + poolname + "." + str(docInfo.fragments(i).mediumidx))
		      end if
		      
		      md5calculator.Process(content)
		      
		    wend
		    
		    fragmentStream.Close
		    
		  next i
		  
		  if EncodeHex(md5calculator.Value) <> docInfo.hash then Return new Limnie.Document("Error verifying retrieved document " + uuid)
		  
		  Return docInfo
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function rollbackInitPool(poolname as string) As string
		  // returns either error message or empty for success
		  dim ErrorPrefix as string = "Error rolling back new pool creation: " 
		  
		  if IsNull(activeVFS) = true then return ErrorPrefix + "VFS session is no longer active"
		  
		  activeVFS.SQLExecute("DROP TABLE " + poolname)
		  if activeVFS.Error = true then return ErrorPrefix + "Rollback pool init fail: "+ activeVFS.ErrorMessage
		  
		  activeVFS.SQLExecute("DELETE FROM pools WHERE name = '" + poolname + "'")
		  if activeVFS.Error = true then return ErrorPrefix + "Rollback pool init fail: "+ activeVFS.ErrorMessage
		  
		  
		  Return empty  // success
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function rollbackPushData(targetDoc as Limnie.Document, PlainPasswd as Variant) As String
		  if IsNull(activeVFS) then return "Error rolling back document: Active VFS is invalid"
		  
		  dim errors(-1) as string
		  dim setMediumOK as Limnie.Medium
		  
		  for i as integer = 0 to targetDoc.fragments.Ubound
		    
		    activeVFS.SQLExecute("DELETE FROM " + targetDoc.pool + " WHERE objidx = " + str(targetDoc.fragments(i).objidx))  // delete records belonging to fragments created so far
		    if activeVFS.Error = true then Errors.Append "Error deleting fragment record " + str(targetDoc.fragments(i).objidx) + " : " + activeVFS.ErrorMessage
		    
		    setMediumOK = setActiveMedium(targetDoc.pool , targetDoc.fragments(i).mediumidx , PlainPasswd)
		    
		    if setMediumOK.error then 
		      errors.Append "Error loading medium " + targetDoc.pool + "." + str(targetDoc.fragments(i).mediumidx) + " : " + setMediumOK.errorMessage
		    else
		      activeMedium.SQLExecute("DELETE FROM content WHERE objidx = " + str(targetDoc.fragments(i).objidx))
		      if activeMedium.Error = true then Errors.Append "Error deleting fragment content " + targetDoc.pool + "." + str(targetDoc.fragments(i).mediumidx) + " : " + activeMedium.ErrorMessage
		    end if
		    
		  next i
		  
		  if Errors.Ubound < 0 then
		    return empty  // all ok
		  else
		    Return  join(errors , " // ")
		  end if
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function setActiveMedium(poolname as string, idx as integer, optional PlainPasswd as Variant = nil) As Limnie.Medium
		  dim mediumDetails as Limnie.Medium = getMediumDetails(poolname , idx)
		  if mediumDetails.error then return mediumDetails
		  
		  dim poolDetails as Limnie.Pool = getPoolDetails(poolname)
		  if poolDetails.error then Return new Limnie.Medium("Error getting pool " + poolname + " details: " + poolDetails.errorMessage)
		  
		  dim saltedPassword as string = ""
		  
		  if poolDetails.encrypted then 
		    
		    dim verifyOK as Pair 
		    
		    if PlainPasswd.IsNull then // class user has not provided a password, using the event/cache Method
		      
		      Return new Limnie.Medium("Password expected for encrypted pool but not provided!")
		      
		    else  // class user has provided a password, we need to validate
		      
		      if PlainPasswd.Type <> Variant.TypeString then Return new Limnie.Medium("Supplied password not textual, error verifying!")
		      
		      saltedPassword = preparePassword(plainPasswd.StringValue , pooldetails.salt)  
		      verifyOK = testPoolPassword(poolname , saltedPassword)
		      
		      select case verifyOK.Left.IntegerValue
		      case 0  // all ok
		        // nothing to do
		      case 1  // infrastructure failure
		        return new Limnie.Medium("Error verifying password for creating next encrypted medium: " + verifyOK.Right.StringValue , 1)
		      case 2 // password mismatch (or db corruption, but we can't really tell the difference)
		        Return new Limnie.Medium("Password not verified!")
		      else  // isn't supposed to happen
		        Return new Limnie.Medium("Internal error!")
		      end select
		      
		      
		    end if
		    
		  end if
		  
		  // maybe medium is already open? no need to close and reopen if so
		  if IsNull(activeMedium) = False then
		    if activeMedium.DatabaseFile.NativePath = mediumDetails.file.NativePath then Return mediumDetails  // activeMedium is already the Medium we're looking to set active
		  end if
		  
		  closeActiveMedium
		  
		  activeMedium = new SQLiteDatabase
		  activeMedium.DatabaseFile = mediumDetails.file
		  
		  if poolDetails.encrypted then
		    activeMedium.EncryptionKey = saltedPassword
		  else
		    activeMedium.EncryptionKey = empty
		  end if
		  
		  #If DebugBuild then
		    System.DebugLog(CurrentMethodName + ":EncryptionKey = " + activeMedium.EncryptionKey + ".")
		  #Endif
		  
		  if activeMedium.Connect then
		    activeMedium.MultiUser = true  // important!
		    Return mediumDetails
		  else
		    mediumDetails.error = True
		    mediumDetails.errorMessage = activeMedium.ErrorMessage
		    mediumDetails.errorCode = 1
		    closeActiveMedium
		    Return mediumDetails
		  end if
		  
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function testPoolPassword(poolname as string, saltedPassword as string) As pair
		  // returns pair: left = error code (0=ok , 1= could not test , 2=probably no match) right = error message
		  
		  dim mediumInfo as Limnie.Medium = getMediumDetails(poolname , 1)  // passwords are tested against medium 1 of each pool
		  if mediumInfo.error = true then return new pair(1 , "Error getting medium details: " + mediumInfo.errorMessage)
		  
		  dim testDB as new SQLiteDatabase
		  testDB.DatabaseFile = mediumInfo.folder.Child(mediumFilename)
		  testDB.EncryptionKey = saltedPassword
		  
		  if testDB.DatabaseFile = nil then return new pair(1 , "Invalid medium file path while verifying password for pool <" + poolname + ">")
		  if testDB.DatabaseFile.Exists = false then return new pair(1 , "Missing medium file while verifying password for pool <" + poolname + ">")
		  
		  if testDB.Connect = False then 
		    testDB.Close
		    return new pair(2 , "Connection failed while verifying password for pool <" + poolname + ">")
		  else // connection ok, password is correct
		    testDB.close
		    return new Pair(0 , empty)
		  end if
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function updatePool(targetPool as Limnie.Pool) As Limnie.Pool
		  // this method can update the following:
		  // pool.friendlyName , pool.comments , pool.rootFolder , pool.mediumThreshold , pool.autoExpand
		  // it goes without saying that update is not retroactive: it will have no effect on media created prior to it
		  
		  if IsNull(activeVFS) then return new Limnie.Pool("Session is not active!")
		  if IsNull(targetPool) then return new Limnie.Pool("Target pool object is null")
		  
		  if getPoolNames.IndexOf(targetPool.name) < 0 then Return new Limnie.Pool("Error updating pool " + targetPool.name + " : Does not seem to exist!")
		  
		  if IsNull(targetPool.rootFolder) then return new Limnie.Pool("New root path is invalid!")
		  if targetPool.rootFolder.Exists = false then return new Limnie.Pool("New target root does not exist!")
		  if targetPool.rootFolder.IsReadable = False then return new Limnie.Pool("New target root is not readable!")
		  if targetPool.rootFolder.IsWriteable = false then Return new Limnie.Pool("New target root is not writeable!")
		  if targetPool.rootFolder.Directory = false then return new Limnie.Pool("New target root is not a directory!")
		  
		  if targetPool.mediumThreshold < 512 then return new Limnie.Pool("New medium threshold should be at least 512 MB")
		  
		  targetPool.comments = targetPool.comments.SuperTrim
		  targetPool.friendlyName = targetPool.friendlyName.SuperTrim
		  
		  // code maybe succeptible to sql injection -- marked for improvement
		  dim updateStatement as string = "UPDATE pools SET "
		  
		  updateStatement = updateStatement + "friendlyname = " + targetPool.friendlyName.sqlQuote + " , "
		  updateStatement = updateStatement + "comments = " + targetPool.comments.sqlQuote + " , "
		  updateStatement = updateStatement + "rootfolder = " + targetPool.rootFolder.NativePath.sqlQuote + " , "
		  updateStatement = updateStatement + "sizelimit = " + str(targetPool.mediumThreshold) + " , "
		  updateStatement = updateStatement + "autoexpand = " + targetPool.autoExpand.sqlQuote 
		  
		  updateStatement = updateStatement + " WHERE name = " + targetPool.name.sqlQuote
		  
		  activeVFS.SQLExecute(updateStatement)
		  
		  if activeVFS.Error then return new Limnie.Pool("Error updating pool details: " + activeVFS.ErrorMessage)
		  
		  return targetPool
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function validateUUID(uuid as String) As Boolean
		  if uuid.len <> 36 then return false
		  if uuid.CountFields("-") <> 5 then return false
		  if uuid.InStr(" ") > 0 then return false
		  
		  for i as Integer = 1 to 5
		    if EncodeHex(DecodeHex(uuid.NthField("-" , i))).Uppercase <> uuid.NthField("-" , i).Uppercase then Return false
		  next i
		  
		  return true
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private activeMedium As SQLiteDatabase
	#tag EndProperty

	#tag Property, Flags = &h21
		Private activeVFS As SQLiteDatabase
	#tag EndProperty

	#tag Property, Flags = &h21
		Private ErrorMsg As string = """"""
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
