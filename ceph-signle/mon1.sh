#!/bin/bash

sudo docker run -itd \
    --name monnode \
    --network ceph-network \
    --ip 172.20.0.11 \
    --restart always \
    -v /myceph/etc/ceph:/etc/ceph \
    -v /myceph/var/lib/ceph/:/var/lib/ceph/ \
    -v /myceph/var/log/ceph/:/var/log/ceph/ \
    -e CLUSTER=ceph \
    -e WEIGHT=1.0 \
    -e MON_IP=172.20.0.11 \
    -e MON_NAME=monnode \
    -e CEPH_PUBLIC_NETWORK=172.20.0.0/16 \
    ceph/daemon mon

