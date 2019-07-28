# thirdway: an experiment in content services backend architecture
\
_thirdway_ is an exploration on the viability of a content delivery architecture in a document management system.\
The problem it is trying to address, is binary content storage & delivery via an RDBMS. It gets its name from the debate around the following question: 
>**"How should I store my binary content? As blobs directly into the database, or as files in the filesystem, while keeping their paths referenced in a database field?"**

We won't go into the pros and cons of each approach (there's plenty of material around it in forums), but if we arbitrarily call the blob approach "the first way" and the filesystem approach "the second way", then what we'd be suggesting here could be "a third way".

### So, what is _thirdway_ ?

Architecturally speaking, it consists of the following:
* Several client apps + 1 controller app ALL connecting to a PostgreSQL database. Clients and controller never talk directly to each other. The demo app includes both roles (+1 more for initial setup), all selectable at startup.
* The database minimally contains two tables: the document repository (thirdway.repository) and the content cache (thirdway.cache)
* A document (a single record in the repository table) consists of status information, user metadata (here just one field) and a UUID reference to a _Limnie_ binary object.
* [Limnie](https://github.com/gregorplop/Limnie) is an object storage mechanism. In thirdway, it is automatically configured to have just one pool (defaultpool) where each document's binary content is stored in 8Mbyte-long _fragments_.
* The software responsible for performing I/O on the Limnie is the controller. This is the reason why the controller needs to run on the same machine the Limnie's media reside.
* The database's content cache table is there to temporarily hold binary content a client has requested from the controller. Every record contains (as a blob), one fragment of a document's content (plus some addressing and status fields).
* Clients and the controller communicate by sending asynchronous requests via the PostgreSQL's message queue. This IPC mechanism is based on a modified [pgReQ](https://github.com/gregorplop/pgReQ) session.
* There are two types of requests going around: a PUSH request for importing new data into the system and a PULL request for making previously stored data available for retrieval. Both requests are sent from a client to the controller.

### What sort of communication takes place between the three main actors of a thirdway setup ?

* Apparently, these three actors are the client (there can be multiple), the controller (acting as a gateway to the Limnie) and the PostgreSQL database server.
* Both the thirdway clients and controller are themselves ordinary clients of the database server. The clients always open one session to the server, while the controller can fire up multiple request-handling threaded workers, each in its own db session.
* **In a PUSH scenario,** a new document is created and its binary content needs to be stored (pushed) into the Limnie pool.
* The client is responsible for creating the repository record (initially in an "invalid" state) and upload the binary content as fragments into the cache table. It then has to send a PUSH request to the controller and wait for its response (or for the response timeout)
* When the controller receives that PUSH request, it creates a new Limnie object and one by one, it reads the fragments from the cache table and stores them into the default pool. When finished without error, it will change the document's repository record to "valid" and will (optionally) clear the cached content. It will then respond to the PUSH request, signaling success. 
* While the controller is handling the PUSH request, the client is waiting for a response to that request. It will either receive it or there will be a timeout. The timeout period is calculated according to the size of the document, but it's really arbitrary and it will likely lead to problems in a production implementation.
* **In a PULL scenario,** the client needs access to the content of certain document, whose UUID is known.
* The client calls the PULL method that initially checks (locally) whether this particular document is already cached. If it is, it immediately returns that information to the calling method and makes no request to the controller: This is a cache hit.
* If the content is not cached, the controller will have to get involved. A PULL request is sent by the client and when the controller receives it, assigns a worker to pull all the document fragments from the Limnie media to the database cache table.
* When all fragments are written to the cache table, a response is sent back to the client. The PULL concludes with the data waiting in the cache table. The client is now free to download the content from the database server.

### Design characteristics of a thirdway-inspired implementation (the PROs)
* The content storage is not the RDBMS itself, saving the DBA the trouble to maintain a huge database. The cache table could be safely excluded from your backup policy. Moreover, an automated cache invalidation and cleanup process could run at set intervals and make sure the cache does not grow beyond a certain limit.
* The content is not stored as individual files on the filesystem, paving the way for inconsistencies between what the document table says there is and what there actually is (for whatever reason: improperly assigned rights in combination with careless users, negligent sysadmins, ransomware attacks, you name it...)
* Faster backup/migration/access rights update on the content: The filesystem objects subject to these operations are a few GByte-long files (the Limnie media), not a gazillion of 100kb PDFs.
* Simplicity and...RADness I (if there can be such word!): your client apps need one session to the database server to handle authentication, queries, metadata retrieval, content retrieval, IPC with a centralized control authority.
* Simplicity and RADness II: Server-side, you only need to implement any extra business functionality in the controller service app (other than the content I/O that is). All the rest is handled by the (super-reliable) PostgreSQL database server.

### More design characteristics of a thirdway-inspired implementation (the CONs)
* Overall, content transfer is going to be inherently slower, particularly in the case of a cache miss: The content needs to be read from its storage and written to an intermediate buffer (the cache table) and then the requestor be notified that it's clear to finally read it. However, this extra delay might be tolerable for small documents, low loads and fast/powerful infrastructure. And then, there's the case of a cache hit...
* Because of the nature of the content cache (a table in the database), read operations by clients will require write operations on the server disk, putting some strain on the non-volatile medium its tablespace is assigned on. Unfortunately, in-memory tables do not exist in PostgreSQL and assigning the cache table tablespace to a ramdrive is a very, VERY bad idea (seriously, don't even think about it!). I've done my best, declaring the cache table as unlogged, but always keep this point in mind.
* Difficult-to-impossible to scale the solution upwards, for a variety of reasons, almost-all database imposed. **Let's face it: this architecture is best suited for the rapid development of a client-server information system of no more than 100-150 users, within a company intranet.** The specific constraints could be some of the following:
* Limited throughput of the PostgreSQL asynchronous queue consequently limits the ammount of requests the controller can serve.
* Each client application requires (at least) one dedicated session to the database server and most probably, no connection pooler can be used (to my knowledge, incompatible with the asynchronous queue, feel free to correct me)
* No possibility of using a database cluster with multiple servers in live replication (again, problems with the asynchronous queue, again, I'd be delighted you prove me wrong)

### A quick start guide -or else, what to do to see what this thing is about:

### Some final notes
* So, who could find it worthy of her/his time to look at this project a bit more thoroughly? **I think if you need to build a small-to-medium-scale document management application (desktop or web), then you might get some inspiration (especially if you haven't done it before)**
* If you **do** take the time to study the demo application, here are some themes that you will come across:
   - Using a Limnie object storage.
   - Using a variation of the pgReQ request handler.
   - Maintaining your army of workers (in the controller).
   - Treating a database table as a read/write stream (in the controller worker).
* All development and testing was done on Windows. I have no idea how well it's going to work on MacOS or Linux.
* You might notice several style inconsistencies and/or ~~obscenities~~ in the way the code has been structured. Remember: it's just a proof of concept!
* Oh, and yes, I did think of Large Objects instead of the cache table but the problem with these is that you cannot change their tablespace! They can only reside in the default system tablespace (wearing *that* down, see CONs, point 2). But seriously, having an in-memory LO-style storage mechanism would have been uber-cool! Any postgres developers out there, listening?


