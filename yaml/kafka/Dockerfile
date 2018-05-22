FROM openjdk:8-jre-alpine

RUN apk add --no-cache \
    bash \
    su-exec

ENV KAFKA_USER=kafka \
    KAFKA_DATA_DIR=/var/lib/kafka/data \
    JAVA_HOME=/usr/lib/jvm/default-jvm \
    KAFKA_HOME=/opt/kafka \
    PATH=$PATH:/opt/kafka/bin

ARG KAFKA_DIST=kafka_2.11-0.11.0.2

RUN set -x \
#&& wget -q "http://archive.apache.org/dist/kafka/0.11.0.2/$KAFKA_DIST.tgz" \
    && wget -q "http://192.168.1.3/mirrors/kafka/$KAFKA_DIST.tgz" \
    && export GNUPGHOME="$(mktemp -d)" \
    && mkdir /opt \
    && tar -xzf "$KAFKA_DIST.tgz" -C /opt \
    && rm -r "$GNUPGHOME" "$KAFKA_DIST.tgz"

COPY log4j.properties /opt/$KAFKA_DIST/config/
COPY kafkaGenConfig.sh /opt/$KAFKA_DIST/bin

RUN set -x \
    && ln -s /opt/$KAFKA_DIST $KAFKA_HOME \
    && adduser -D $KAFKA_USER \
    && [ `id -u $KAFKA_USER` -eq 1000 ] \
    && [ `id -g $KAFKA_USER` -eq 1000 ] \
    && mkdir -p $KAFKA_DATA_DIR \
    && chown -R "$KAFKA_USER:$KAFKA_USER"  /opt/$KAFKA_DIST \
    && chown -R "$KAFKA_USER:$KAFKA_USER"  $KAFKA_DATA_DIR
RUN set -x \
    && chmod +x /opt/$KAFKA_DIST/bin/*

