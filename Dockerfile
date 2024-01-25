FROM percona/percona-server-mongodb:5.0-multi
LABEL edu.uky.cs.netrecon.parse-hipaa.vendor="Network Reconnaissance Lab"
LABEL edu.uky.cs.netrecon.parse-hipaa.authors="baker@cs.uky.edu"
LABEL description="HIPAA & GDPR compliant ready Mongo Database with percona-server."

# Set up ssl files and log folder for container
USER root
RUN mkdir ssl logs
RUN chown -R 1001:0 /logs /ssl

# Add default scripts
COPY ./scripts/mongo-init.js /docker-entrypoint-initdb.d/

USER 1001

CMD ["mongod", "--logpath", "/logs/mongo.log", "--logappend", "--auditDestination=file", "--auditPath", "/logs/audit.json"]
