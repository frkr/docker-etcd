# etcd swarm

This image is based on Alpine Linux. The `-data-dir` is a volume mounted to `/data`, and the default ports are bound to etcd and exposed. This image DOES NOT expose the old, deprecated etcd ports. It only exposes ports 2379 and 2380.

- ETCD_VERSION=3.2.17

## Environment Variables

These settings may be overwritten by defining the variables at run time or passing them as CLI flags to the container. CLI flags override any environment variables with the same name.

- `SERVICE_NAME` - The service name when using a Swarm cluster.
- `CLUSTER_SIZE` - The initial size of a cluster. Defaults to 1.
- `ETCD_NAME` - This will be unique when running as a service on Swarm, defaults to `etcd` when running as a standalone container.
- `ETCD_LISTEN_CLIENT_URLS` - Defaults to `http://0.0.0.0:2379`.
- `ETCD_ADVERTISE_CLIENT_URLS` -  Defaults to `http://$IP_OF_CONTAINER:2379`, manually define this if running as a single container.
- `ETCD_LISTEN_PEER_URLS` -  Defaults to `http://0.0.0.0:2380`, only used if starting as cluster.
- `ETCD_INITIAL_ADVERTISE_PEER_URLS ` - Defaults to `http://$IP_OF_CONTAINER:2379`,  only used if starting as cluster.
- `ETCD_INITIAL_CLUSTER` - The image will use Swarm DNS to generate an appropiate INITIAL_CLUSTER setting, only used if starting as cluster.
- `TASK_SLOT={{.Task.Slot}}` - Better inform which slot 

## Using the image

```bash
docker service create -d --name etcd \
--network teste \
--replicas 3 -e CLUSTER_SIZE=3 \
-e TASK_SLOT={{.Task.Slot}} \
-e SERVICE_NAME=etcd \
frkr/etcd:latest
```

## Scaling Up Swarm Service

This image can handle new containers being added to the Swarm service. The container will run etcdctl to add itself as a new member then attempt to run etcd.

**WARNING**: Only scale up the service ONE AT A TIME. If the service is scaled up more than one at a time, the containers may not join the cluster correctly. Then you're stuck with having to rebuild the cluster unless you're lucky enough to scale down and it kills one of the problematic containers. This is being worked on. You have been warned.
