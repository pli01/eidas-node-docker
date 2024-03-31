#
# System settings
#
: ${JVM_MAX_HEAP:=1536m}
: ${JVM_START_HEAP:=512m}

## detect https_proxy
if [ ! -z "${https_proxy_host}" ] ; then
  CATALINA_OPTS="$CATALINA_OPTS -Dhttps.proxyHost=${https_proxy_host}"
fi
if [ ! -z "${https_proxy_port}" ] ; then
  CATALINA_OPTS="$CATALINA_OPTS -Dhttps.proxyPort=${https_proxy_port}"
fi
if [ ! -z "${no_proxy}" ] ; then
  CATALINA_OPTS="$CATALINA_OPTS -Dhttps.nonProxyHosts=${no_proxy}"
fi
# http.proxyUser
# http.proxyPassword

# enable console logging properties (disable file logs)
export CATALINA_LOGGING_CONFIG="-Djava.util.logging.config.file=$CATALINA_BASE/conf/console_logging.properties"

export JAVA_OPTS="$JAVA_OPTS $JAVA_OPTS_CUSTOM"

# See also https://apacheignite.readme.io/docs/getting-started#running-ignite-with-java-11-and-later-versions regarding add-exports
export CATALINA_OPTS="$CATALINA_OPTS \
  -Djdk.tls.client.protocols=TLSv1.2 \
  -Dorg.apache.xml.security.ignoreLineBreaks=true \
  -Dfile.encoding=UTF-8 \
  -Djava.net.preferIPv4Stack=true \
  -XX:+UseG1GC -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:+ScavengeBeforeFullGC \
  --add-exports=java.base/jdk.internal.misc=ALL-UNNAMED \
  --add-exports=java.base/sun.nio.ch=ALL-UNNAMED \
  --add-exports=java.management/com.sun.jmx.mbeanserver=ALL-UNNAMED \
  --add-exports=jdk.internal.jvmstat/sun.jvmstat.monitor=ALL-UNNAMED \
  --add-exports=java.base/sun.reflect.generics.reflectiveObjects=ALL-UNNAMED \
  --add-opens=jdk.management/com.sun.management.internal=ALL-UNNAMED \
  --illegal-access=permit \
  -Xmx${JVM_MAX_HEAP} \
  -Xms${JVM_START_HEAP} \
"


