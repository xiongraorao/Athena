#!/bin/bash
set -e
sed -i "s#\${GISMAP_PATH}#${GISMAP_PATH}#g" ${CATALINA_HOME}/webapps/geowebcache/WEB-INF/geowebcache-core-context.xml 
mkdir -p ${GISMAP_PATH}
/usr/local/tomcat/bin/catalina.sh run
