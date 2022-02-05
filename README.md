# container-apache-zookeeper

[![CI](https://github.com/poppelaars/container-apache-zookeeper/workflows/Build/badge.svg?branch=main&event=push)](https://github.com/poppelaars/container-apache-zookeeper) [![Docker pulls](https://img.shields.io/docker/pulls/poppelaars/container-apache-zookeeper.svg?maxAge=2592000)](https://hub.docker.com/r/poppelaars/container-apache-zookeeper/)

Container with Apache Zookeeper.

# Introduction
This container provides an out-of-the-box working, standalone, Apache Zookeeper node that can be used for developing, or with certain reconfiguration for production purposes.

The standalone node is provisioned with:
* secure client port: "2281";
* SASL authentication;
* Auditing enabled;
* Quorum TLS (for demonstration);
* Quorum authentication (for demonstration);
* Log4j RollingFileAppender;
* self-signed certificate;
* Jolokia JMX with security enabled.

Filesystem paths inside container:
* /etc/zookeeper
* /opt/zookeeper
* /var/lib/zookeeper
* /var/log/zookeeper

This image can also be used for building an Apache Zookeeper cluster. The configuration files in this repo can be used as templates.

# Build container
Use the following command to build the container image.
```bash
docker build -t container-apache-zookeeper .
```

# Start standalone Apache Zookeeper node
Use the following command the start a standalone Apache Zookeeper node.
```bash
docker run --name zookeeper --restart always -p 2281:2281 -p 8778:8778 -d container-apache-zookeeper
```

# Zookeeper CLI/Shell

The Zookeeper CLI/Shell is included with the software but can also run outside the container as standalone, so usage is depending on your implementation.

Depending on the type of authentication, adjust the next piece of code according to your specific implementation.
```bash
export KAFKA_OPTS="
-Dzookeeper.clientCnxnSocket=org.apache.zookeeper.ClientCnxnSocketNetty
-Dzookeeper.client.secure=true
-Dzookeeper.ssl.keyStore.location=/etc/zookeeper/keystore.p12
-Dzookeeper.ssl.keyStore.password=password
-Dzookeeper.ssl.trustStore.location=/etc/zookeeper/truststore.p12
-Dzookeeper.ssl.trustStore.password=password
-Djava.security.auth.login.config=/etc/zookeeper/zookeeper.jaas"
```

Create a zookeeper.jaas file, adjust credentials according to your environment.
```bash
Client {
    org.apache.zookeeper.server.auth.DigestLoginModule required
    username="root"
    password="password";
};
```

Export KAFKA_OPTS to your environment and start the Zookeeper CLI with the following command:
```bash
/opt/zookeeper/bin/zookeeper-shell.sh <zookeeper node>:2281
```

# ACLs
This chapter describes various ACL configurations.

## Apache Zookeeper
Remember to change username(s) according to your environment.
```bash
setAcl / sasl:root:cdrwa
setAcl /zookeeper sasl:root:cdrwa
```

## Apache Kafka
Remember to change username(s) according to your environment.
```bash
setAcl / sasl:root:cdrwa,sasl:kafka:cr
setAcl /zookeeper sasl:root:cdrwa
create /kafka "" sasl:root:cdrwa,sasl:kafka:cdrwa
```
