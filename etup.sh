#!/bin/sh
if [ "$(hostname -i)" != "$1" ]; then
    curl -Ss http://$1:2379/v2/members -XPOST \
    -H "Content-Type: application/json" -d "{\"peerURLs\":[\"http://$(hostname -i):2380\"]}"
#    etcdctl member add $2 http://$1:2380
fi
