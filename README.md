# thirdway: an experiment in content services backend architecture
\
_thirdway_ is an exploration on the viability of a content delivery architecture in a document management system.\
The problem it is trying to address is binary content storage & delivery via an RDBMS and it gets its name from the debate around the question: 
>**"How should I store my binary content? As blobs directly into the database, or as files in the filesystem, while keeping their paths referenced in a database field?"**

We won't go into the pros and cons of each solution (there's plenty of material around it in forums), but if we call the blob approach "the first way" and the filesystem approach "the second way", then what we'd be suggesting here could be "the third way".

### So, what is _thirdway_ ?

As an architecture, it implements the following:
* Several client apps + 1 controller app ALL connecting to a PostgreSQL database. Clients and controller never talk directly to each other. The demo app includes both roles (+1 more for initial setup), all selectable at startup.
* The database minimally contains two tables: the document repository (thirdway.repository) and the content cache (thirdway.cache)
* A document (a single record in the repository table) consists of status information, user metadata (here just one field) and a UUID reference to a _Limnie_ binary object.
* The [Limnie](https://github.com/gregorplop/Limnie) is an object storage mechanism. In thirdway, it is automatically configured to have just one pool (defaultpool) where each document's binary content is stored in 8Mbyte-long _fragments_.
* The database's content cache table is there to temporarily hold binary content a client has requested from the controller. Every record contains (as a blob), one fragment of a document's content (plus some addressing and status fields).
* Clients and the controller communicate by sending asynchronous requests via the PostgreSQL's message queue. This IPC mechanism is based on a modified [pgReQ](https://github.com/gregorplop/pgReQ) session.
* There are two types of requests going around: a PUSH request for importing new data into the system and a PULL request for making previously stored data avalable for retrieval. Both requests are sent from a client to the controller.
* In a PUSH scenario, 

