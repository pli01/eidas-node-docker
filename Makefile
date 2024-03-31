#
# default var
#
DOCKER_BUILD_ARGS= # --no-cache
DOCKER_BUILD_NAME=eidas-node
DOCKER_DEFAULT_PLATFORM=linux/amd64
export
#
# eidas-node with wildfy
#
build-wildfly: build-eidas-node-wildfly build-eidas-node-mock-wildfly
# eidas-node only
build-eidas-node-wildfly:
	docker build ${DOCKER_BUILD_ARGS} -t ${DOCKER_BUILD_NAME}:wildfly-latest docker/wildfly
# full eidas-node with mock
build-eidas-node-mock-wildfly:
	docker build ${DOCKER_BUILD_ARGS} -t ${DOCKER_BUILD_NAME}-mock:wildfly-latest --target mock docker/wildfly

run-wildfly: run-eidas-node-mock-wildfly
down-wildfly: down-eidas-node-mock-wildfly
run-eidas-node-mock-wildfly:
	docker-compose -f docker-compose-wildfly.yaml up ${DOCKER_BUILD_NAME}-mock
down-eidas-node-mock-wildfly:
	docker-compose -f docker-compose-wildfly.yaml down ${DOCKER_BUILD_NAME}-mock
#
# eidas-node with tomcat
#
build-tomcat: build-eidas-node-tomcat build-eidas-node-mock-tomcat
# eidas-node only
build-eidas-node-tomcat:
	docker build ${DOCKER_BUILD_ARGS} -t ${DOCKER_BUILD_NAME}:tomcat-latest docker/tomcat
# full eidas-node with mock
build-eidas-node-mock-tomcat:
	docker build ${DOCKER_BUILD_ARGS} -t ${DOCKER_BUILD_NAME}-mock:tomcat-latest --target mock docker/tomcat

run-tomcat: run-eidas-node-mock-tomcat
down-tomcat: down-eidas-node-mock-tomcat
run-eidas-node-mock-tomcat:
	docker-compose -f docker-compose-tomcat.yaml up ${DOCKER_BUILD_NAME}-mock
down-eidas-node-mock-tomcat:
	docker-compose -f docker-compose-tomcat.yaml down ${DOCKER_BUILD_NAME}-mock
#
# dummy test
#
test-localhost-eidas-node:
	curl -L localhost:8080/EidasNode/ServiceMetadata
	curl -L localhost:8080/EidasNode/ConnectorMetadata
	curl -L localhost:8080/SP/
	curl -L localhost:8080/IdP/
	curl -L localhost:8080/SpecificProxyService
	curl -L localhost:8080/SpecificConnector
