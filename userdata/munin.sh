#!/bin/bash

SERVICE=munin

# POSTGRES

echo "export DB_URL=jdbc:postgresql://postgres:${POSTGRES_PORT}/${POSTGRES_DB}" > /etc/profile.d/postgres.sh
echo "export DB_USER=$POSTGRES_USER" >> /etc/profile.d/postgres.sh
echo "export DB_PASSWORD=$POSTGRES_PASSWORD" >> /etc/profile.d/postgres.sh
echo "export MUNIN_QUERY_WORKER='SELECT 1'" >> /etc/profile.d/postgres.sh
source /etc/profile.d/postgres.sh

# API

echo "export PEPE_ENDPOINT=http://api:8080/api" > /etc/profile.d/pepe-api.sh
source /etc/profile.d/pepe-api.sh

# KEYSTONE

echo "export KEYSTONE_URL=http://keystone:5000/v3" > /etc/profile.d/keystone.sh
echo "export KEYSTONE_USER=admin" >> /etc/profile.d/keystone.sh
echo "export KEYSTONE_PASSWORD=ADMIN_PASS" >> /etc/profile.d/keystone.sh
echo "export KEYSTONE_DOMAIN=default" >> /etc/profile.d/keystone.sh
echo "export KEYSTONE_PROJECT=admin" >> /etc/profile.d/keystone.sh
source /etc/profile.d/keystone.sh

# RPM

yum install -y /mnt/jdk/*.rpm
yum install -y /mnt/dists/pepe-${SERVICE}-*el7.noarch.rpm

# START

PID_FILE="/opt/logs/pepe/${SERVICE}/pepe.pid"
JAVA_VMS="-Xms1024m"
JAVA_VMX="-Xmx1024m"
su -l -s /bin/bash pepe <<EOF
source /opt/pepe/${SERVICE}/scripts/pepe.sh || true; \
/usr/bin/java \
  -server \
  -XX:+UseParallelGC \
  -XX:+PerfDisableSharedMem \
  -Djavax.net.ssl.keyStore=/etc/pki/java/cacerts \
  -Djavax.net.ssl.trustStore=/etc/pki/java/cacerts \
  -Dcom.sun.management.jmxremote.port=9999 \
  -Dcom.sun.management.jmxremote.authenticate=false \
  -Dcom.sun.management.jmxremote.ssl=false \
  -Dcom.sun.management.jmxremote=true \
  -Dlogging.config=/mnt/src/main/resources/log4j2.xml \
  -DLog4jContextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector \
  ${JAVA_VMS} \
  ${JAVA_VMX} \
  -jar /opt/pepe/${SERVICE}/lib/pepe.jar
EOF

#EOF
