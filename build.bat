docker build -t frkr/etcd .
docker push frkr/etcd

docker network create --driver overlay --attachable teste

docker service rm etcd
docker service create -d --name etcd --network teste --replicas 3 -e CLUSTER_SIZE=3 -e TASK_SLOT={{.Task.Slot}} -e SERVICE_NAME=etcd frkr/etcd:latest
