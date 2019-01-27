#!/bin/sh

sleep 10

log() {
    echo "$(date +"%s %FT%T") [$(hostname)|$(hostname -i)] $@"
};

SERVICE_NAME=${SERVICE_NAME:-}
CLUSTER_SIZE=${CLUSTER_SIZE:-1}
SERVICE_CONTAINERS=""
NUM_OF_PEERS=0
CMD="/bin/etcd -data-dir /data"

MY_SERVICE_IP=$(hostname -i)

if [ -z "$SERVICE_NAME" ]; then
    log ERROR Service name not found
    exit 1
fi

# Get a list of the containers that are a part of this service
getServiceContainers() {
    SERVICE_CONTAINERS=$(dig tasks.$SERVICE_NAME +short)
    NUM_OF_PEERS=$(echo "$SERVICE_CONTAINERS" | wc -l)
    log INFO Service containers: $SERVICE_CONTAINERS
    log INFO Num of peers: $NUM_OF_PEERS
}
getServiceContainers

# Wait for all initial cluster nodes to start and added to DNS
while [ $NUM_OF_PEERS -lt $CLUSTER_SIZE ]; do
    log INFO Waiting for other members to start
    log INFO Cluster Size: $CLUSTER_SIZE
    log INFO Found Peers: $NUM_OF_PEERS
    log INFO ...
    sleep 1
    getServiceContainers
done

# If a cluster already exists, wait for this containers IP to be added to DNS
while [ -z "$(drill -x $MY_SERVICE_IP | grep $SERVICE_NAME)" ]; do
    log INFO Waiting to be added to DNS
    sleep 1
    getServiceContainers
done

ETCD_LISTEN_CLIENT_URLS="http://$(hostname -i):2379"
ETCD_LISTEN_PEER_URLS="http://$(hostname -i):2380"

CMD="$CMD -listen-client-urls ${ETCD_LISTEN_CLIENT_URLS}"

ETCD_NAME=etcd$TASK_SLOT
CMD="$CMD -name $ETCD_NAME"

ETCD_ADVERTISE_CLIENT_URLS="http://$MY_SERVICE_IP:2379"
CMD="$CMD -advertise-client-urls ${ETCD_ADVERTISE_CLIENT_URLS}"

ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$MY_SERVICE_IP:2380"
CMD="$CMD -initial-advertise-peer-urls ${ETCD_INITIAL_ADVERTISE_PEER_URLS}"

## Setup cluster
#if [ $NUM_OF_PEERS -gt 1 ]; then
#
#    # Build initial cluster IPs
#    if [ -z "${ETCD_INITIAL_CLUSTER}" ]; then
#        ETCD_INITIAL_CLUSTER=""
#
#        for peerAddress in $SERVICE_CONTAINERS; do
#            peerName=etcd$(drill -x $peerAddress | grep $SERVICE_NAME | cut -f 5 | cut -d'.' -f2)
#            ETCD_INITIAL_CLUSTER="${ETCD_INITIAL_CLUSTER}${peerName}=http://${peerAddress}:2380,"
#        done
#
#        ETCD_INITIAL_CLUSTER="${ETCD_INITIAL_CLUSTER%?}"
#    fi
#
#    CMD="$CMD -listen-peer-urls ${ETCD_LISTEN_PEER_URLS} -initial-cluster ${ETCD_INITIAL_CLUSTER} -initial-advertise-peer-urls ${ETCD_INITIAL_ADVERTISE_PEER_URLS}"
#fi

CMD="$CMD $*"

log INFO "Starting etcd: $CMD"

exec $CMD &

# Joining an existing cluster
if [ $NUM_OF_PEERS -gt $CLUSTER_SIZE ]; then
    log INFO Joining existing cluster

    ENDPOINTS=""
    for peerAddress in $SERVICE_CONTAINERS; do
        ENDPOINTS="${ENDPOINTS}http://${peerAddress}:2379,"
    done
    ENDPOINTS="${ENDPOINTS%?}"
    log INFO Endpoints: $ENDPOINTS

    export ETCDCTL_API=3
    etcdctl_out=$(etcdctl --endpoints="${ENDPOINTS}" member add ${ETCD_NAME} --peer-urls="http://$MY_SERVICE_IP:2380")
    etcdctl_exit_code=$?

    # Check if multiple members are attempting to join
    if [ -n "$(echo "$etcdctl_out" | grep 'unhealthy cluster')" ]; then
        log ERROR Cluster can not accept new members right now
        exit 1
    fi

    # Check for other errors
    if [ $etcdctl_exit_code -ne 0 ]; then
        log ERROR Error adding new member to cluster
        exit 1
    fi

    CMD="$CMD -initial-cluster-state existing"
else
    log INFO Joining new cluster
fi

while true;
do
    #log INFO heartbeat OK
    sleep 10
done
