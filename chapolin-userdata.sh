#!/bin/bash

echo "export RABBIT_URL=\"amqp://$RABBITMQ_DEFAULT_USER:$RABBITMQ_DEFAULT_PASS@127.0.0.1:$RABBITMQ_PORT\"" > /etc/profile.d/rabbit.sh
echo "export RABBIT_MANAGEMENT_LOGIN=$RABBITMQ_DEFAULT_USER" >> /etc/profile.d/rabbit.sh
echo "export RABBIT_MANAGEMENT_PASSWORD=$RABBITMQ_DEFAULT_PASS" >> /etc/profile.d/rabbit.sh

source /etc/profile.d/rabbit.sh

yum install -y /mnt/jdk/java-11-amazon-corretto-devel-11.0.3.7-1.x86_64.rpm
yum install -y /mnt/dists/pepe-chapolin-1.0.0.el7.noarch.rpm



sleep 600
