#!/bin/sh

log() {
    echo "$(date +"%s %FT%T") [$(hostname)|$(hostname -i)] $@"
};

if [ -z $TASK_SLOT ]; then
    log ERROR TASK_SLOT nao esta configurado
    exit 1
fi
if [ -z $SERVICE_NAME ]; then
    log ERROR SERVICE_NAME nao esta configurado
    exit 1
fi

etcd -data-dir /data \
--name task$TASK_SLOT \
--initial-advertise-peer-urls http://$(hostname -i):2380 \
--advertise-client-urls http://$(hostname -i):2379 \
--listen-client-urls http://$(hostname -i):2379 \
--listen-peer-urls http://$(hostname -i):2380 &

dig tasks.$SERVICE_NAME +short | xargs -I task etup task task$TASK_SLOT

while true;
do
    #log INFO heartbeat OK
    sleep 10
done
