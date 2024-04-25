ARG ALPINE_VERSION=3.19
ARG TOMCAT_VERSION=9.0.87-jre11
ARG TOMCAT_USER=tomcat

# Stage builder
FROM alpine:${ALPINE_VERSION} as builder

RUN apk update && \
    apk add --no-cache unzip curl

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

# Unzip eIDAS-Node Software
RUN unzip eIDAS-node-${EIDAS_NODE_VERSION}.zip EIDAS-Binaries-Tomcat-${EIDAS_NODE_VERSION}.zip && \
    unzip EIDAS-Binaries-Tomcat-${EIDAS_NODE_VERSION}.zip && \
    # extract sample server config
    unzip TOMCAT/config.zip -d config


# Stage runner
FROM tomcat:${TOMCAT_VERSION} as runner

USER root
# non root user
ARG TOMCAT_USER
RUN apt-get -qy update  ; apt-get install -qy unzip

RUN groupadd -r ${TOMCAT_USER} -g 1000 && \
    useradd -u 1000 -r -g ${TOMCAT_USER} -M -d /usr/local/tomcat -s /sbin/nologin -c "${TOMCAT_USER} user" ${TOMCAT_USER} && \
    chown -R ${TOMCAT_USER}:${TOMCAT_USER} /usr/local/tomcat

# Copy default WAR to Tomcat Image
COPY --from=builder --chown=${TOMCAT_USER}:${TOMCAT_USER} /data/TOMCAT/EidasNode.war /usr/local/tomcat/webapps/
# Copy bouncycastle lib
COPY --from=builder --chown=${TOMCAT_USER}:${TOMCAT_USER} /data/lib/*.jar /opt/java/openjdk/lib/
# Copy customized java security properties file to /etc/java/security
COPY files/tomcat/java_bc.security /opt/java/openjdk/conf/security/java_bc.security
# Copy customized tomcat configuration files
COPY files/tomcat/bin/setenv.sh /usr/local/tomcat/bin/
COPY files/tomcat/conf/server.xml /usr/local/tomcat/conf/
# Copy ccustomized logging.properties to send logs to console
COPY files/tomcat/conf/console_logging.properties /usr/local/tomcat/conf/

RUN mkdir -p /config/eidas/specificProxyService && \
    mkdir -p /config/keystore && \
    mkdir -p /work && \
    # unzip war because of secure readonly FS
    unzip /usr/local/tomcat/webapps/EidasNode.war -d /usr/local/tomcat/webapps/EidasNode ; rm -rf /usr/local/tomcat/webapps/EidasNode.war ; \
    chown -R ${TOMCAT_USER}:${TOMCAT_USER} /config && \
    chown -R ${TOMCAT_USER}:${TOMCAT_USER} /work && \
    # Provide Bouncycastle Module and overwrite security providers
    printf '\nJAVA_OPTS="$JAVA_OPTS -Djava.security.properties=/opt/java/openjdk/conf/security/java_bc.security --module-path /opt/java/openjdk/lib/bcprov-jdk18on-1.77.jar --add-modules org.bouncycastle.provider"\n' \
      >> /usr/local/tomcat/bin/setenv.sh && \
    chown -R ${TOMCAT_USER}:${TOMCAT_USER} /usr/local/tomcat

USER ${TOMCAT_USER}

ENV EIDAS_CONFIG_REPOSITORY=/config/eidas
ENV SPECIFIC_CONNECTOR_CONFIG_REPOSITORY=$EIDAS_CONFIG_REPOSITORY/specificConnector
ENV SPECIFIC_PROXY_SERVICE_CONFIG_REPOSITORY=$EIDAS_CONFIG_REPOSITORY/specificProxyService
ENV SP_CONFIG_REPOSITORY=$EIDAS_CONFIG_REPOSITORY/sp
ENV IDP_CONFIG_REPOSITORY=$EIDAS_CONFIG_REPOSITORY/idp

ENV CATALINA_OPTS=""
ENV JAVA_OPTS=""
ENV JAVA_OPTS_CUSTOM="-Xmx512m"


# Stage mock
FROM runner as mock
ARG TOMCAT_USER
COPY --from=builder --chown=${TOMCAT_USER}:${TOMCAT_USER} /data/TOMCAT/IdP.war /usr/local/tomcat/webapps/
COPY --from=builder --chown=${TOMCAT_USER}:${TOMCAT_USER} /data/TOMCAT/SP.war /usr/local/tomcat/webapps/
COPY --from=builder --chown=${TOMCAT_USER}:${TOMCAT_USER} /data/TOMCAT/SpecificConnector.war /usr/local/tomcat/webapps/
COPY --from=builder --chown=${TOMCAT_USER}:${TOMCAT_USER} /data/TOMCAT/SpecificProxyService.war /usr/local/tomcat/webapps/
# Copy server config
COPY --from=builder --chown=${TOMCAT_USER}:${TOMCAT_USER} /data/config/ /tmp/config/

# Copy server config
RUN cp -r /tmp/config/tomcat/* /config/eidas/ && \
    cp -r /tmp/config/keystore/* /config/keystore/ && \
    rm -rf /tmp/config && \
    # unzip war because of secure readonly FS
    ( for war in IdP SP SpecificConnector SpecificProxyService ; do unzip /usr/local/tomcat/webapps/$war.war -d /usr/local/tomcat/webapps/$war ; rm -rf /usr/local/tomcat/webapps/$war.war ; done ) && \
    chown -R ${TOMCAT_USER}:${TOMCAT_USER} /config /usr/local/tomcat

# Stage last (default)
FROM runner as last
