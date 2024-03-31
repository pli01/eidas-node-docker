ARG ALPINE_VERSION=3.19
ARG WILDFLY_VERSION=26.1.3.Final-jdk11

# Stage builder
FROM alpine:${ALPINE_VERSION} as builder

RUN apk update && \
    apk add --no-cache unzip curl openjdk17

WORKDIR /data

ARG EIDAS_NODE_VERSION=2.6.0
ARG EIDAS_NODE_URL=https://ec.europa.eu/digital-building-blocks/artifact/repository/eid/eu/eIDAS-node/${EIDAS_NODE_VERSION}/eIDAS-node-${EIDAS_NODE_VERSION}.zip

# Download eIDAS-Node Software
RUN curl -LO ${EIDAS_NODE_URL}

# Download BouncyCastle provider
ARG BOUNCYCASTLE_VERSION=1.77
ARG BOUNCYCASTLE_URL=https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk18on/${BOUNCYCASTLE_VERSION}/bcprov-jdk18on-${BOUNCYCASTLE_VERSION}.jar

RUN mkdir -p lib && \
    ( cd lib && curl -LO ${BOUNCYCASTLE_URL} )

# Prepare for adding updated jboss-deployment-structure.xml file to EidasNode.war
# Because of Bug: https://issues.apache.org/jira/browse/IGNITE-12483
# Solution: https://stackoverflow.com/questions/59407347/connection-from-ignite-client-in-docker-container-to-ignite-server-in-another-do
COPY files/wildfly/jboss-deployment-structure.xml WEB-INF/jboss-deployment-structure.xml

# Unzip eIDAS-Node Software
RUN unzip eIDAS-node-${EIDAS_NODE_VERSION}.zip EIDAS-Binaries-Wildfly-${EIDAS_NODE_VERSION}.zip && \
    unzip EIDAS-Binaries-Wildfly-${EIDAS_NODE_VERSION}.zip && \
    # Update the EidasNode.war by adding and overwriting jboss-deployment-structure.xml
    jar -uvf WILDFLY/EidasNode.war WEB-INF/ && \
    # extract sample server config
    unzip WILDFLY/config.zip -d config


# Stage runner
FROM quay.io/wildfly/wildfly:${WILDFLY_VERSION} as runner

USER root

# Copy default WAR to Wildfly Image
COPY --from=builder --chown=jboss:root /data/WILDFLY/EidasNode.war /opt/jboss/wildfly/standalone/deployments/EidasNode.war
# Copy additional files to tmp
COPY --from=builder --chown=jboss:root /data/AdditionalFiles/ /tmp/AdditionalFiles/
# Copy bouncycastle lib
COPY --from=builder --chown=jboss:root /data/lib/*.jar /opt/jboss/wildfly/modules/system/layers/base/org/bouncycastle/main/
# Copy customized java security properties file to /etc/java/security
COPY files/wildfly/java_bc.security /etc/java/security/java_bc.security

RUN mkdir -p /config/eidas/specificProxyService && \
    mkdir -p /config/keystore && \
    mkdir -p /work && \
    chown -R jboss:root /config && \
    chown -R jboss:root /work && \
    # Copy wildfly latest additional files to WildFly Modules
    LATEST_ADDITIONAL_FILES=$(ls /tmp/AdditionalFiles/ | tail -n 1) && \
    cp -r /tmp/AdditionalFiles/${LATEST_ADDITIONAL_FILES}/* /opt/jboss/wildfly/modules/system/layers/base/ && \
    rm -r /tmp/AdditionalFiles/ && \
    # See also https://apacheignite.readme.io/docs/getting-started#running-ignite-with-java-11-and-later-versions regarding add-exports
    printf '\nJAVA_OPTS=\"$JAVA_OPTS $JAVA_OPTS_CUSTOM -Djdk.tls.client.protocols=TLSv1.2 --add-exports=java.base/jdk.internal.misc=ALL-UNNAMED --add-exports=java.management/com.sun.jmx.mbeanserver=ALL-UNNAMED --add-exports=jdk.internal.jvmstat/sun.jvmstat.monitor=ALL-UNNAMED --add-exports=java.base/sun.reflect.generics.reflectiveObjects=ALL-UNNAMED --add-opens=jdk.management/com.sun.management.internal=ALL-UNNAMED --illegal-access=permit\"' \
      >> /opt/jboss/wildfly/bin/standalone.conf && \
    # Provide Bouncycastle Module and overwrite security providers
    printf '\nJAVA_OPTS=\"$JAVA_OPTS -Djava.security.properties=/etc/java/security/java_bc.security --module-path /opt/jboss/wildfly/modules/system/layers/base/org/bouncycastle/main/bcprov-jdk18on-1.77.jar --add-modules org.bouncycastle.provider\"\n' \
      >> /opt/jboss/wildfly/bin/standalone.conf

USER jboss

ENV EIDAS_CONFIG_REPOSITORY=/config/eidas
ENV SPECIFIC_CONNECTOR_CONFIG_REPOSITORY=$EIDAS_CONFIG_REPOSITORY/specificConnector
ENV SPECIFIC_PROXY_SERVICE_CONFIG_REPOSITORY=$EIDAS_CONFIG_REPOSITORY/specificProxyService
ENV SP_CONFIG_REPOSITORY=$EIDAS_CONFIG_REPOSITORY/sp
ENV IDP_CONFIG_REPOSITORY=$EIDAS_CONFIG_REPOSITORY/idp

ENV JAVA_OPTS=""
ENV JAVA_OPTS_CUSTOM="-Xms512m -Xmx512m"


# Stage mock
FROM runner as mock
USER root
COPY --from=builder --chown=jboss:root /data/WILDFLY/IdP.war /opt/jboss/wildfly/standalone/deployments/IdP.war
COPY --from=builder --chown=jboss:root /data/WILDFLY/SP.war /opt/jboss/wildfly/standalone/deployments/SP.war
COPY --from=builder --chown=jboss:root /data/WILDFLY/SpecificConnector.war /opt/jboss/wildfly/standalone/deployments/SpecificConnector.war
COPY --from=builder --chown=jboss:root /data/WILDFLY/SpecificProxyService.war /opt/jboss/wildfly/standalone/deployments/SpecificProxyService.war
# Copy server config
COPY --from=builder --chown=jboss:root /data/config/ /tmp/config/

# Copy server config
RUN cp -r /tmp/config/wildfly/* /config/eidas/ && \
    cp -r /tmp/config/keystore/* /config/keystore/ && \
    rm -rf /tmp/config && \
    chown -R jboss:root /config
USER jboss

# Stage last (default)
FROM runner as last
