FROM percona/percona-server-mongodb:4.4
LABEL edu.uky.cs.netrecon.parse-hipaa.vendor="Network Reconnaissance Lab"
LABEL edu.uky.cs.netrecon.parse-hipaa.authors="baker@cs.uky.edu"
LABEL description="HIPAA & GDPR compliant ready Mongo Database."

# Set up ssl files and log folder for container
USER root
RUN mkdir mongossl mongologs
RUN chown -R 1001:0 /mongologs /mongossl

USER 1001

CMD ["mongod", "--logpath", "/mongologs/mongo.log", "--logappend", "--auditDestination=file", "--auditPath", "/mongologs/audit.json"]