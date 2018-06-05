#!/bin/sh
set -x
# config redis
echo "config start ..."
if [ -n "${REDIS_HOST}" ]; then     
    sed -i "s#\${REDIS_HOST}#${REDIS_HOST}#g" config.json
else
    sed -i "s#\${REDIS_HOST}#127.0.0.1#g" config.json
fi
if [ -n "${REDIS_PORT}" ]; then     
    sed -i "s#\${REDIS_PORT}#${REDIS_PORT}#g" config.json
else
    sed -i "s#\${REDIS_PORT}#6379#g" config.json
fi  

sed -i "s#\${REDIS_PWD}#${REDIS_PWD}#g" config.json

# config threads
if [ -n "${CLASSIFY_THREADS}" ]; then     
    sed -i "s#\${CLASSIFY_THREADS}#${CLASSIFY_THREADS}#g" config.json
else
    sed -i "s#\${CLASSIFY_THREADS}#1#g" config.json
fi
if [ -n "${DETECT_THREADS}" ]; then     
    sed -i "s#\${DETECT_THREADS}#${DETECT_THREADS}#g" config.json
else
    sed -i "s#\${DETECT_THREADS}#2#g" config.json
fi
if [ -n "${FEATURE_THREADS}" ]; then     
    sed -i "s#\${FEATURE_THREADS}#${FEATURE_THREADS}#g" config.json
else
    sed -i "s#\${FEATURE_THREADS}#1#g" config.json
fi
if [ -n "${SEARCH_THREADS}" ]; then     
    sed -i "s#\${SEARCH_THREADS}#${SEARCH_THREADS}#g" config.json
else
    sed -i "s#\${SEARCH_THREADS}#1#g" config.json
fi
echo "config succeed"
cat config.json
# start verifier
# RESTFUL
./verifier
# ZMQ 
# ./router & ./verifier