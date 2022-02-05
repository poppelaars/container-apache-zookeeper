FROM openjdk:17.0.2-slim
LABEL maintainer="Chris Poppelaars"
ARG DEBIAN_FRONTEND=noninteractive


ENV SCALA_VERSION 2.13
ENV KAFKA_VERSION 3.1.0
ENV JOLOKIA_VERSION 1.7.1
ENV SOFTWARE_URL https://dlcdn.apache.org/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz
ENV ASC_URL https://downloads.apache.org/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz.asc
ENV KEYS_URL https://downloads.apache.org/kafka/KEYS
ENV CHECKSUM_URL https://downloads.apache.org/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz.sha512
ENV JOLOKIA_DOWNLOAD https://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-jvm/$JOLOKIA_VERSION/jolokia-jvm-$JOLOKIA_VERSION.jar


ENV PATH $PATH:/opt/zookeeper/bin
RUN adduser --disabled-password --gecos '' zookeeper


RUN savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
    apt-get upgrade -y; \
	apt-get install -y --no-install-recommends \
		gnupg \
        wget \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
    cd /tmp; \
	wget --progress=dot:giga -O kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz "$SOFTWARE_URL"; \
    wget --progress=dot:giga -O kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz.asc "$ASC_URL"; \
    wget --progress=dot:giga -O KEYS "$KEYS_URL"; \
    wget --progress=dot:giga -O kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz.sha512 "$CHECKSUM_URL"; \
    wget --progress=dot:giga -O jolokia-jvm-$JOLOKIA_VERSION.jar "$JOLOKIA_DOWNLOAD"; \
    \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --import KEYS; \
    gpg --batch --verify kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz.asc kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz; \
    DIFF=$(gpg --print-md SHA512 kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz | diff - kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz.sha512); \
    if [ "$DIFF" ]; then exit 1; fi; \
    rm -rf "$GNUPGHOME"; \
	\
    mkdir -p /etc/zookeeper; \
    mkdir -p /opt/zookeeper; \
    mkdir -p /var/lib/zookeeper; \
    mkdir -p /var/log/zookeeper; \
    chown -R zookeeper:zookeeper /etc/zookeeper /var/lib/zookeeper /var/log/zookeeper; \
    \
	tar --extract \
		--file kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz \
		--directory /opt/zookeeper \
		--strip-components 1 \
		--no-same-owner \
	; \
    mv jolokia-jvm-$JOLOKIA_VERSION.jar /opt/zookeeper/jolokia-jvm.jar; \
	rm -rf kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz* KEYS; \
	\
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false;


COPY kafka-run-class.sh /opt/zookeeper/bin/
COPY zookeeper.properties /etc/zookeeper/
COPY log4j.properties /etc/zookeeper/
COPY zookeeper.jaas /etc/zookeeper/
COPY jolokia.properties /etc/zookeeper/
COPY jolokia-access.xml /etc/zookeeper/
COPY docker-entrypoint.sh /

EXPOSE 2181 2888 3888 8778

USER zookeeper

ENV _JAVA_OPTIONS -Djava.net.preferIPv4Stack=true
ENV KAFKA_OPTS -Djava.security.auth.login.config=/etc/zookeeper/zookeeper.jaas \
    -javaagent:/opt/zookeeper/jolokia-jvm.jar=config=/etc/zookeeper/jolokia.properties
ENV KAFKA_LOG4J_OPTS -Dlog4j.configuration=file:/etc/zookeeper/log4j.properties
ENV KAFKA_HEAP_OPTS -Xms512m -Xmx512m
ENV LOG_DIR /var/log/zookeeper

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["zookeeper-server-start.sh", "/etc/zookeeper/zookeeper.properties"]
