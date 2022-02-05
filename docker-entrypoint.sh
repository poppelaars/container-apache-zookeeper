#!/bin/bash

if [[ ! -e "/var/lib/zookeeper/myid" ]]; then
    myid=$(cat /etc/zookeeper/zookeeper.properties | grep $(hostname -s) | grep -oP '(?<=server.)\d')
    echo "${myid:-1}" > /var/lib/zookeeper/myid;
fi

if [[ ! -e "/etc/zookeeper/keystore.p12" ]]; then
    keytool -genkey -keyalg RSA \
        -keystore /etc/zookeeper/keystore.p12 \
        -alias zookeeper \
        -storepass password \
        -storetype PKCS12 \
        -validity 365 \
        -keysize 2048 \
        -dname "cn=$(hostname -s), ou=OU, o=O, c=C";

    keytool -export \
        -rfc \
        -keystore /etc/zookeeper/keystore.p12 \
        -alias zookeeper \
        -file /etc/zookeeper/zookeeper.crt \
        -storepass password;
fi

if [[ ! -e "/etc/zookeeper/truststore.p12" && -e "/etc/zookeeper/zookeeper.crt" ]]; then
    keytool -import \
        -keystore /etc/zookeeper/truststore.p12 \
        -storetype PKCS12 \
        -alias zookeeper \
        -file /etc/zookeeper/zookeeper.crt \
        -storepass password \
        -noprompt;
fi

exec "$@"
