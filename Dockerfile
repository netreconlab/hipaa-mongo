FROM percona/percona-server-mongodb:4.0.9
MAINTAINER Network Reconnaissance Lab <baker@cs.uky.edu>

#All arguments
ARG sslDir
ARG replicaAuth

#Set up ssl files and log log folder for container
USER root
RUN mkdir mongossl mongologs
ADD $sslDir /mongossl/
WORKDIR /mongossl
COPY $sslDir/../rootCA.pem $sslDir/../mongo_auth.key ./
RUN chown -R 1001:0 /mongologs mongodb_encryption.key mongo_auth.key
RUN chmod 400 mongo_auth.key

ENTRYPOINT ["/entrypoint.sh"]

USER 1001

CMD ["mongod"]
