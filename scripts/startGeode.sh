#!/bin/bash

# Attempt to set APP_HOME
# Resolve links: $0 may be a link
PRG="$0"
# Need this for relative symlinks.
while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`"/$link"
    fi
done
SAVED="`pwd`"
cd "`dirname \"$PRG\"`/.." >&-
APP_HOME="`pwd -P`"
cd "$SAVED" >&-

DEFAULT_LOCATOR_MEMORY="--initial-heap=128m --max-heap=128m"

DEFAULT_SERVER_MEMORY="--initial-heap=1g --max-heap=1g"

DEFAULT_JVM_OPTS=" --J=-XX:+UseParNewGC"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:+UseConcMarkSweepGC"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:CMSInitiatingOccupancyFraction=50"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:+CMSParallelRemarkEnabled"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:+UseCMSInitiatingOccupancyOnly"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:+ScavengeBeforeFullGC"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:+CMSScavengeBeforeRemark"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-XX:+UseCompressedOops"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --mcast-port=0"
DEFAULT_JVM_OPTS="$DEFAULT_JVM_OPTS --J=-Djava.net.preferIPv4Stack=true"

STD_SERVER_ITEMS="--rebalance --start-rest-api=true "

LOCATORS="localhost[10334]"

# --J=-Dlog4j.configurationFile=${APP_HOME}/etc/log4j.xml
function waitForPort {

    (exec 6<>/dev/tcp/127.0.0.1/$1) &>/dev/null
    while [ $? -ne 0 ]
    do
        echo -n "."
        sleep 1
        (exec 6<>/dev/tcp/127.0.0.1/$1) &>/dev/null
    done
}

function launchLocator() {
    mkdir -p ${APP_HOME}/data/locator$1
    gfsh -e "start locator ${DEFAULT_LOCATOR_MEMORY} ${DEFAULT_JVM_OPTS} --name=locator$1 --port=1033$1 --dir=${APP_HOME}/data/locator$1 --locators=${LOCATORS}" &
}

function launchServer() {
    mkdir -p ${APP_HOME}/data/server${1}
    gfsh -e "start server ${DEFAULT_SERVER_MEMORY} ${DEFAULT_JVM_OPTS} --name=server${1} --dir=${APP_HOME}/data/server${1} ${STD_SERVER_ITEMS} --locators=${LOCATORS} --http-service-port=707${1} --server-port=4040${1}" &
}


for i in {4..4}
do
    launchLocator ${i}
done
wait

for i in {1..3}
do
    launchServer ${i}
done

wait

gfsh -e "connect --locator=${LOCATORS}" -e "create region --name=test --type=PARTITION_REDUNDANT"
