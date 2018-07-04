#!/bin/bash
set -e 
sed -i "s#\${ZK_HOST}#${ZK_HOST}#g" ${KAFKA_HOME}/kafkaGenConfig.sh
/opt/kafka/bin/kafkaGenConfig.sh && /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
