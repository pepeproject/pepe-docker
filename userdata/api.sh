#!/bin/bash

SERVICE=api

# DB

echo "export DB_API_DRIVER=com.mysql.cj.jdbc.Driver" > /etc/profile.d/db.sh
echo "export DB_API_URL='jdbc:mysql://mysql:3306/pepe?autoReconnect=true&useSSL=false'" >> /etc/profile.d/db.sh
echo "export DB_API_USER=root" >> /etc/profile.d/db.sh
echo "export DB_API_PASSWORD=password" >> /etc/profile.d/db.sh
echo "export DB_API_DDL=none" >> /etc/profile.d/db.sh
echo "export DB_API_DIALECT=org.hibernate.dialect.MySQL57InnoDBDialect" >> /etc/profile.d/db.sh
source /etc/profile.d/db.sh

# KEYSTONE

echo "export KEYSTONE_URL=http://keystone:5000/v3" > /etc/profile.d/keystone.sh
echo "export KEYSTONE_DOMAIN_CONTEXT=default" >> /etc/profile.d/keystone.sh
source /etc/profile.d/keystone.sh

# RABBITMQ

echo "export RABBIT_URL=\"amqp://$RABBITMQ_DEFAULT_USER:$RABBITMQ_DEFAULT_PASS@rabbitmq:$RABBITMQ_PORT\"" > /etc/profile.d/rabbit.sh
echo "export RABBIT_MANAGEMENT_LOGIN=$RABBITMQ_DEFAULT_USER" >> /etc/profile.d/rabbit.sh
echo "export RABBIT_MANAGEMENT_PASSWORD=$RABBITMQ_DEFAULT_PASS" >> /etc/profile.d/rabbit.sh
echo "export RABBIT_MANAGEMENT_URL=http://rabbitmq:15672/api" >> /etc/profile.d/rabbit.sh
source /etc/profile.d/rabbit.sh

# Stackstorm

while ! echo > /dev/tcp/stackstorm/443; do sleep 1; done

limit=60 # timeout
count=0
while :; do
    count=$[count+1]
    TOKEN="$(curl -k -s -X POST -u $ST2_USER:$ST2_PASSWORD -H'Accept: */*' -H'content-type: application/json' --data-binary '{}' https://stackstorm/auth/tokens | python -c 'import sys, json; print json.load(sys.stdin)["token"]')"
    APIKEY="$(curl -k -s -X POST -H'Accept: */*' -H'content-type: application/json' -H'X-Auth-Token: '${TOKEN}  --data-binary '{}' https://stackstorm/api/v1/apikeys | python -c 'import sys, json; print json.load(sys.stdin)["key"]')"
    [ "x${APIKEYS}" != "x" ] && break || sleep 1
    [ ${count} -ge ${limit} ] && break
done
echo "export STACKSTORM_KEY=$APIKEY" > /etc/profile.d/stackstorm.sh
echo "export STACKSTORM_API_URL=https://stackstorm" >> /etc/profile.d/stackstorm.sh
echo "export STACKSTORM_AUTH_URL=https://stackstorm" >> /etc/profile.d/stackstorm.sh
echo "export STACKSTORM_STREAM_URL=https://stackstorm" >> /etc/profile.d/stackstorm.sh
source /etc/profile.d/stackstorm.sh

# RPM

yum install -y /mnt/jdk/*.rpm
yum install -y /mnt/dists/pepe-${SERVICE}-*el7.noarch.rpm

# Flyway
export JAVA_HOME=/usr/lib/jvm/java
cd /mnt && ./mvnw -Dflyway.user=${DB_API_USER} -Dflyway.password=${DB_API_PASSWORD} -Dflyway.url=${DB_API_URL} flyway:migrate

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
