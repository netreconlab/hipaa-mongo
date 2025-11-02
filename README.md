# hipaa-mongo
 
[![](https://dockeri.co/image/netreconlab/hipaa-mongo)](https://hub.docker.com/r/netreconlab/hipaa-mongo)
[![Docker](https://github.com/netreconlab/hipaa-mongo/actions/workflows/build.yml/badge.svg)](https://github.com/netreconlab/hipaa-mongo/actions/workflows/build.yml)
[![Docker](https://github.com/netreconlab/hipaa-mongo/actions/workflows/release.yml/badge.svg)](https://github.com/netreconlab/hipaa-mongo/actions/workflows/release.yml)

---

A simple Mongo image designed for [parse-hipaa](https://github.com/netreconlab/parse-hipaa) but can be used anywhere Mongo is used. These docker images include the necessary database auditing and logging for HIPAA compliance. hipaa-mongo is derived from [percona-server-mongodb](https://hub.docker.com/r/percona/percona-server-mongodb/).

hipaa-mongo provides the following:
- [x] Auditing & logging
- [x] Ready for encryption in transit - run behind a proxy with files & directions on how to [complete the process](https://github.com/netreconlab/parse-hipaa#deploying-on-a-real-system) with Nginx and LetsEncrypt 

You will still need to setup the following on your own to be fully HIPAA compliant:

- [ ] Encryption in transit - you will need to [complete the process](https://github.com/netreconlab/parse-hipaa#deploying-on-a-real-system)
- [ ] Encryption at rest - Mount to your own encrypted storage drive (Linux and macOS have API's for this) and store the drive in a "safe" location
- [ ] Be sure to do anything else HIPAA requires

The [CareKitSample-ParseCareKit](https://github.com/netreconlab/CareKitSample-ParseCareKit) app uses this image alongise parse-hipaa and [ParseCareKit](https://github.com/netreconlab/ParseCareKit). If you are looking for a Postgres variant, checkout [hipaa-postgres](https://github.com/netreconlab/hipaa-postgres).

**Use at your own risk. There is not promise that this is HIPAA compliant and we are not responsible for any mishandling of your data**

## Images
Multiple images are automatically built for your convenience. Images can be found at the following locations:
- [Docker - Hosted on Docker Hub](https://hub.docker.com/r/netreconlab/hipaa-mongo)
- [Singularity - Hosted on GitHub Container Registry](https://github.com/netreconlab/hipaa-postgres/pkgs/container/hipaa-mongo)

## Environment Variables

Changing these variables also require the same changes to be made to the [initialization script](https://github.com/netreconlab/hipaa-mongo/blob/8997d535a105c839c014644f53102b33bcb9cc5d/scripts/mongo-init.js#L3-L4) or to the database directly.

```
MONGO_INITDB_ROOT_USERNAME=parse # Username for logging into database
MONGO_INITDB_ROOT_PASSWORD=parse # Password for logging into database
MONGO_INITDB_DATABASE=parse_hipaa # Name of parse-hipaa database
```

## Setting up TLS

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

`docker run --name hipaa-mongodb-container0 -t hipaa-mongodb:latest --sslMode requireSSL --sslPEMKeyFile /ssl/mongodb.pem --sslCAFile /ssl/rootCA.pem --enableEncryption --encryptionKeyFile /ssl/mongodb_encryption.key --replSet rs0 --keyFile /ssl/mongo_auth.key --logpath /logs/mongo.log --logappend --auditDestination=file --auditPath /logs/audit.json`

If you want to persist your data and access the generated logs and audit files, you should volume mount the directories from your host machine. For example, if mongodb was installed on your host machine via brew on macOS and you want to use the mongodb directories. You can start your container with the following command:

`docker run --name hipaa-mongodb-container0 -v /usr/local/var/mongodb:/data/db -v /usr/local/var/log/mongodb:/logs -t hipaa-mongodb:latest --sslMode requireSSL --sslPEMKeyFile /ssl/mongodb.pem --sslCAFile /ssl/rootCA.pem --enableEncryption --encryptionKeyFile /ssl/mongodb_encryption.key --keyFile /ssl/mongo_auth.key --logpath /logs/mongo.log --logappend --auditDestination=file --auditPath /logs/audit.json`

To enable replica sets. You will need to start your intended primary container with '--replSet rs0'. You can learn more about replica sets here, https://docs.mongodb.com/manual/tutorial/deploy-replica-set/. Starting your container will look something like the following:

`docker run --name hipaa-mongodb-container0 -v /usr/local/var/mongodb:/data/db -v /usr/local/var/log/mongodb:/logs -t hipaa-mongodb:latest --sslMode requireSSL --sslPEMKeyFile /ssl/mongodb.pem --sslCAFile /ssl/rootCA.pem --enableEncryption --encryptionKeyFile /ssl/mongodb_encryption.key --keyFile /ssl/mongo_auth.key --logpath /logs/mongo.log --logappend --auditDestination=file --auditPath /logs/audit.json --replSet rs0`

You can then use `rs.initiate()`, `rs.status()` from the previous tutorial to add replica members. Adterwards, start the new container using the same "replSet" name:

`docker run --name hipaa-mongodb-container1 -v /usr/local/var/mongodb:/data/db -v /usr/local/var/log/mongodb:/logs -t hipaa-mongodb:latest --sslMode requireSSL --sslPEMKeyFile /ssl/mongodb.pem --sslCAFile /ssl/rootCA.pem --enableEncryption --encryptionKeyFile /ssl/mongodb_encryption.key --keyFile /ssl/mongo_auth.key --logpath /logs/mongo.log --logappend --auditDestination=file --auditPath /logs/audit.json --replSet rs0`

Note that if you use --auth to start your containers, you will need to remove this command during initial syncing of your DB's. You can re-enable -auth after they are synced.  
