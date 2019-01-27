docker build -t frkr/etcd .
docker push frkr/etcd

docker network create --driver overlay --attachable teste

docker service rm etcd
docker service create -d --name etcd --network teste -e CLUSTER_SIZE=1 -e TASK_SLOT={{.Task.Slot}} -e SERVICE_NAME=etcd frkr/etcd:latest
