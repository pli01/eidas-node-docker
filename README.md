# eIDAS-Node Docker Image

This repository provides Dockerfiles of the [EU eIDAS-Node Software](https://ec.europa.eu/digital-building-blocks/sites/display/DIGITAL/All+releases)

At the moment, this project is only suitable for test and demonstration

2 Applications Servers are provided in this repository
- [WildFly](https://www.wildfly.org/)
- [Tomcat](https://tomcat.apache.org/)
- JDK: OpenJDK Runtime Environment Temurin-11 [temurin](https://adoptium.net/fr/temurin/)

WildFly Dockerfile and Kubernetes demo are inspired by the work of https://github.com/ecsec/eidas-node-docker

Requirements:
- make
- docker
- docker-compose

eIDAS-Node Images are available:
- eidas-node : eIDAS-Node with only EidasNode component
- eidas-node-mock : eIDAS-Node with all components (EidasNode, IdP, SP, SpecificConnector, SpecificProxyService) and demo configuration files

There is also a kubernetes demo, in kubernetes directory.

## Versions

- eIDAS-Node

| Build Argument | Description | Default |
| -------------- | ----------- | ------- |
| EIDAS_NODE_VERSION | Version of the eIDAS-Node software | 2.6.0 |
| EIDAS_NODE_URL | Defines the entire URL that is pointing to the ZIP-Archive of the eIDAS-Node Software. | `https://ec.europa.eu/cefdigital/artifact/repository/eid/eu/eIDAS-node/${EIDAS_NODE_VERSION}/eIDAS-node-${EIDAS_NODE_VERSION}.zip` |
| BOUNCYCASTLE_VERSION | Defines the version of the BouncyCastle provider | `1.77` |
| BOUNCYCASTLE_URL | Defines the URL for the BouncyCastle provider | `https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk18on/${BOUNCYCASTLE_VERSION}/bcprov-jdk18on-${BOUNCYCASTLE_VERSION}.jar` |

- WildFly

| Build Argument | Description | Image | Default |
| -------------- | ----------- | ------- | --- |
| ALPINE_VERSION | Version of the Alpine Image that is used for downloading, extracting and preparing the eIDAS-Node software | alpine | 3.19 |
| WILDFLY_VERSION | Version of the WildFly Application Server that will be used to run the eIDAS-Node software | quay.io/wildfly/wildfly | 26.1.3.Final-jdk11 |

- Tomcat

| Build Argument | Description | Image | Default |
| -------------- | ----------- | ------- | --- |
| ALPINE_VERSION | Version of the Alpine Image that is used for downloading, extracting and preparing the eIDAS-Node software | alpine | 3.19 |
| TOMCAT_VERSION | Version of the Tomcat Application Server that will be used to run the eIDAS-Node software | tomcat | 9.0.87-jre11 |

## Build

Following eIDAS-Node Images are available:
- eidas-node : eIDAS-Node with only EidasNode component
- eidas-node-mock : eIDAS-Node with all components (EidasNode, IdP, SP, SpecificConnector, SpecificProxyService)

To build one eIDAS-Node Image containing all eIDAS components, use one of the following command:

To build eidas-node with WildFly application server
```bash
$ make build-wildfly

# This will execute the following command: docker build --no-cache --platform=linux/arm64  -t eidas-node:wildfly-latest --target mock docker/wildfly
```

To build eidas-node with Tomcat application server
```bash
$ make build-tomcat

# This will execute the following command: docker build --no-cache --platform=linux/arm64  -t eidas-node:tomcat-latest --target mock docker/tomcat
```

## Configuration

You have to prepare your eIDAS-Node configuration, before running the eIDAS-Node via Docker.
A configuration must be present, otherwise you might receive startup errors.

Default settings provided in the eIDAS-Node release archive are available in the eidas-node-mock docker image.
The content is extracted and available in /config directory in the container
You must adapt to feet to your needs

Those settings must be mounted to the Docker Container. The most essential mount paths are the following:

| Mount Path | Description |
| ---------- | ----------- |
| `/config/eidas` | This is the default directory where your eIDAS-Node configuration files are stored (Can be overwritten via an env variable). |
| `/config/keystore` | This is the default directory where your keystores are stored. |
|| |
| `/opt/jboss/wildfly/standalone/configuration/standalone.xml` | Your WildFly configuration which can be overwritten by a customized one. |
|| |
| `/usr/local/tomcat/conf/` | Your Tomcat configuration which can be overwritten by a customized one. |

In addition, the following environment variables can be overwritten at runtime (by using `--env`):

| Environment Variable | Description | Default |
| -------------------- | ----------- | ------- |
| EIDAS_CONFIG_REPOSITORY | The directory where your eIDAS-Node configuration files are stored. | /config/eidas |
| SPECIFIC_CONNECTOR_CONFIG_REPOSITORY | The directory where your specific connector configuration files are stored. | /config/eidas/specificConnector |
| SPECIFIC_PROXY_SERVICE_CONFIG_REPOSITORY | The directory where your specific proxy service configuration files are stored. | /config/eidas/specificProxyService |
| SP_CONFIG_REPOSITORY | The Service Provider configuration | $EIDAS_CONFIG_REPOSITORY/sp |
| IDP_CONFIG_REPOSITORY | The IdP Provider configuration | $EIDAS_CONFIG_REPOSITORY/idp |
| |||
| JAVA_OPTS_CUSTOM | overwrite JVM arguments. | `-Xmx512m` |
| CATALINA_OPTS | overwrite Tomcat arguments. | `-Xmx512m` |
| SERVER_OPTS | overwrite WildFly arguments. | |


## Run

To start the eIDAS-Node mock Docker container with some default settings:
- customize docker-compose: add environment variables, volumes mount


```bash
# For wildfly
$ make run-wildfly

# This will execute the following command: docker-compose -f docker-compose-wildfly.yaml up eidas-node-mock

# For tomcat
$ make run-tomcat

# This will execute the following command: docker-compose -f docker-compose-tomcat.yaml up eidas-node-mock

```

```bash
# Same with docker command
# For wildfly
$ docker run \
    -p 8080:8080 \
    --mount type=bind,source=<PATH_TO_EIDAS_NODE_CONFIG_FOLDER>/wildfly,target=/config/eidas \
    --mount type=bind,source=<PATH_TO_EIDAS_NODE_CONFIG_FOLDER>/keystore,target=/config/keystore \
    eidas-node-mock:wildfly-latest

# For Tomcat
$ docker run \
    -p 8080:8080 \
    --mount type=bind,source=<PATH_TO_EIDAS_NODE_CONFIG_FOLDER>/tomcat,target=/config/eidas \
    --mount type=bind,source=<PATH_TO_EIDAS_NODE_CONFIG_FOLDER>/keystore,target=/config/keystore \
    eidas-node-mock:tomcat-latest

```

## Validate the demo installation

Extract from eIDAS-Node Installation Quick Start Guide pdf.

To validate the installation, a first test can be performed simulating that a citizen from a country accesses services
in the same country.

1. Open the Service Provider URL : http://localhost:8080/SP
2. Choose for both the SP and citizen country the fictitious country for which your application server has been configured (CA, CB, CC, CD or CF).
3. The generated Simple Protocol Request is displayed. Submit the form.
4. Click *Next* to give your consent to attributes being transferred.
5. Enter the user credentials. Type `xavi` as *Username* and `creus` as *Password* and submit the page.
6. Click Submit to validate the values to transfer. The Simple Protocol Response is displayed.
7. *Submit* the form.

You should see *Login Succeeded.*

