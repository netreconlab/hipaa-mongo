# hipaa_mongodb

Docker file for HIPAA Compliant MongoDB using percona-server-mongodb docker (https://hub.docker.com/r/percona/percona-server-mongodb/). Particulurly enabling ssl, encryption at rest, and auditing. Note that the containers will still need to be stored according HIPAA requirements after setup to maintain compliance. 

**Use at your own risk. There is not promise that this is HIPAA compliant and we are not responsible for any mishandling of your data**

Before building you will need to setup certificates and keys for each of the servers/containers you wish to run. You can follow the tutorial here: https://medium.com/@rajanmaharjan/secure-your-mongodb-connections-ssl-tls-92e2addb3c89

Using the naming conventions from the tuturial. Move the files to follow the file structure below:

- ssl<br />
---- rootCA.pem (this only needs to be created once)<br />
---- server0<br />
-------- mongodb.key (new one for each server)<br />
-------- mongodb.pem (new one for each server)<br />
---- server1 (if you have a second server)<br />
-------- mongodb.key (new one for each server)<br />
-------- mongodb.pem (new one for each server)<br />

Now follow the directions here, https://www.percona.com/doc/percona-server-for-mongodb/LATEST/data_at_rest_encryption.html, and rename "mongodb-keyfile" file to "mongodb_encryption.key". Do this for each server/container and place each one in their respective folder:

- ssl<br />
---- server0<br />
-------- mongodb_encryption.key (new one for each server. Note: if you want to rename this to something else, you need to change the name in Dockerfile as well)<br />

This step enables keyfile access control in a replica set. Currently, even if you are not using a replica set, you will need to do this because of the way the docker file is setup. Follow the directions here, https://docs.mongodb.com/manual/tutorial/enforce-keyfile-access-control-in-existing-replica-set/, and for <path-to-keyfile use the name "mongo_auth.key" and place it:

- ssl<br />
---- mongo_auth.key (this only needs to be created once)<br />

To build the image:
`docker build --tag=hipaa-mongodb --build-arg sslDir=ssl/server0 .`

After a successful build, you can run a ssl enabled container that is HIPAA compliant type:

`docker run --name hipaa-mongodb-container0 -t hipaa-mongodb:latest --sslMode requireSSL --sslPEMKeyFile /mongossl/mongodb.pem --sslCAFile /mongossl/rootCA.pem --enableEncryption --encryptionKeyFile /mongossl/mongodb_encryption.key --replSet rs0 --keyFile /mongossl/mongo_auth.key --logpath /mongologs/mongo.log --logappend --auditDestination=file --auditPath /mongologs/audit.json`

If you want to persist your data and access the generated logs and audit files, you should volume mount the directories from your host machine. For example, if mongodb was installed on your host machine via brew on macOS and you want to use the mongodb directories. You can start your container with the following command:

`docker run --name hipaa-mongodb-container0 -v /usr/local/var/mongodb:/data/db -v /usr/local/var/log/mongodb:/mongologs -t hipaa-mongodb:latest --sslMode requireSSL --sslPEMKeyFile /mongossl/mongodb.pem --sslCAFile /mongossl/rootCA.pem --enableEncryption --encryptionKeyFile /mongossl/mongodb_encryption.key --keyFile /mongossl/mongo_auth.key --logpath /mongologs/mongo.log --logappend --auditDestination=file --auditPath /mongologs/audit.json`

To enable replica sets. You will need to start your intended primary container with '--replSet rs0'. You can learn more about replica sets here, https://docs.mongodb.com/manual/tutorial/deploy-replica-set/. Starting your container will look something like the following:

`docker run --name hipaa-mongodb-container0 -v /usr/local/var/mongodb:/data/db -v /usr/local/var/log/mongodb:/mongologs -t hipaa-mongodb:latest --sslMode requireSSL --sslPEMKeyFile /mongossl/mongodb.pem --sslCAFile /mongossl/rootCA.pem --enableEncryption --encryptionKeyFile /mongossl/mongodb_encryption.key --keyFile /mongossl/mongo_auth.key --logpath /mongologs/mongo.log --logappend --auditDestination=file --auditPath /mongologs/audit.json --replSet rs0`

You can then use `rs.initiate()`, `rs.status()` from the previous tutorial to add replica members. Adterwards, start the new container using the same "replSet" name:

`docker run --name hipaa-mongodb-container1 -v /usr/local/var/mongodb:/data/db -v /usr/local/var/log/mongodb:/mongologs -t hipaa-mongodb:latest --sslMode requireSSL --sslPEMKeyFile /mongossl/mongodb.pem --sslCAFile /mongossl/rootCA.pem --enableEncryption --encryptionKeyFile /mongossl/mongodb_encryption.key --keyFile /mongossl/mongo_auth.key --logpath /mongologs/mongo.log --logappend --auditDestination=file --auditPath /mongologs/audit.json --replSet rs0`

Note that if you use --auth to start your containers, you will need to remove this command during initial syncing of your DB's. You can re-enable -auth after they are synced.  
