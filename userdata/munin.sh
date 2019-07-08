#!/bin/bash

SERVICE=munin

# DB

echo "export DB_MUNIN_DRIVER=com.mysql.cj.jdbc.Driver" > /etc/profile.d/db.sh
echo "export DB_MUNIN_URL=jdbc:mysql://mysql:3306/pepe" >> /etc/profile.d/db.sh
echo "export DB_MUNIN_USER=root" >> /etc/profile.d/db.sh
echo "export DB_MUNIN_PASSWORD=password" >> /etc/profile.d/db.sh
echo "export DB_MUNIN_DDL=none" >> /etc/profile.d/db.sh
echo "export DB_MUNIN_DIALECT=org.hibernate.dialect.MySQL57InnoDBDialect" >> /etc/profile.d/db.sh
source /etc/profile.d/db.sh

# API

echo "export PEPE_ENDPOINT=http://api:8080" > /etc/profile.d/pepe-api.sh
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

# wait pepe-api
while ! echo > /dev/tcp/api/8080; do sleep 1; done

# Add initial data
curl -H'content-type: application/json' -d'{"name":"org.postgresql.Driver", "alias":"postgresql", "jar":"/tmp/postgresql-42.2.6.jar","type":"JDBC" }' ${PEPE_ENDPOINT}/munin/v1/driver
curl -H'content-type: application/json' -d'{"name":"myconnection","url":"jdbc:postgresql://postgres:'${POSTGRES_PORT}'/'${POSTGRES_DB}'", "login":"'${POSTGRES_USER}'","password":"'${POSTGRES_PASSWORD}'", "driver":"http://localhost/driver/1" }' ${PEPE_ENDPOINT}/munin/v1/connection
curl -H'content-type: application/json' -d'{"name": "'${KEYSTONE_PROJECT}'", "keystone":{"login":"'${KEYSTONE_USER}'", "password":"'${KEYSTONE_PASSWORD}'"}}' ${PEPE_ENDPOINT}/munin/v1/project
curl -H'content-type: application/json' -d'{"name": "myquery", "query":"select 1", "trigger":"acs-collector", "connection":"http://localhost/connection/1", "project":"http://localhost/project/1"}' ${PEPE_ENDPOINT}/munin/v1/metric

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
