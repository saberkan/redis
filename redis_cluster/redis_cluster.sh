#!/bin/bash

# Settings
PORT=30000
TIMEOUT=2000
NODES=6
REPLICAS=1

# You may want to put the above config parameters into config.sh in order to
# override the defaults without modifying this script.

if [ -a config.sh ]
then
    source "config.sh"
fi

# Computed vars

NODES=$2
REPLICAS=$3 
ENDPORT=$((PORT+NODES))


if [ "$1" == "create" ]
then
    while [ $((PORT < ENDPORT)) != "0" ]; do
        PORT=$((PORT+1))
        echo "Starting $PORT"
        mkdir $PORT
        cd $PORT
        redis-server --port $PORT --cluster-enabled yes --cluster-config-file nodes-${PORT}.conf --cluster-node-timeout $TIMEOUT --appendonly yes --appendfilename appendonly-${PORT}.aof --dbfilename dump-${PORT}.rdb --logfile ${PORT}.log --daemonize yes
        cd ..
    done

    HOSTS=""
    while [ $((PORT < ENDPORT)) != "0" ]; do
        PORT=$((PORT+1))
        HOSTS="$HOSTS 127.0.0.1:$PORT"
    done
    $REDIS_TRIB create --replicas $REPLICAS $HOSTS
    exit 0
fi

if [ "$1" == "stop" ]
then
    while [ $((PORT < ENDPORT)) != "0" ]; do
        PORT=$((PORT+1))
        echo "Stopping $PORT"
        redis-cli -p $PORT shutdown nosave
    done
    exit 0
fi

if [ "$1" == "watch" ]
then
    PORT=$((PORT+1))
    while [ 1 ]; do
        clear
        date
        redis-cli -p $PORT cluster nodes | head -30
        sleep 1
    done
    exit 0
fi

if [ "$1" == "tail" ]
then
    INSTANCE=$2
    PORT=$((PORT+INSTANCE))
    tail -f ${PORT}.log
    exit 0
fi

if [ "$1" == "call" ]
then
    while [ $((PORT < ENDPORT)) != "0" ]; do
        PORT=$((PORT+1))
        src/redis-cli -p $PORT $2 $3 $4 $5 $6 $7 $8 $9
    done
    exit 0
fi

if [ "$1" == "clean" ]
then
    while [ $((PORT < ENDPORT)) != "0" ]; do
        PORT=$((PORT+1))
        echo "Starting $PORT"
        rm -R $PORT
    done
    exit 0
fi

echo "Usage:                        $0 [create|stop|watch|tail|clean]"
echo "start                         -- Launch Redis Cluster instances."
echo "create <nb_nodes> <replicas>  -- Launch Redis Cluster instances and create a cluster using redis-trib create."
echo "stop                          -- Stop Redis Cluster instances."
echo "watch                         -- Show CLUSTER NODES output (first 30 lines) of first node."
echo "tail <id>                     -- Run tail -f of instance at base port + ID."
echo "clean                         -- Remove all instances data, logs, configs."
