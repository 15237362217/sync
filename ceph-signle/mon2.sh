#!/bin/bash
sudo docker run -itd \
	--privileged=true \
	--name monnode2 \
	--ip 172.20.0.12 \
	--network ceph-network \
	-e CLUSTER=ceph \
	-e WEIGHT=1.0 \
	-e MON_NAME=monnode2 \
	-e MON_IP=172.20.0.12 \
	-e CEPH_PUBLIC_NETWORK=172.20.0.0/16 \
	-v /myceph/mon2/etc/ceph:/etc/ceph \
	-v /myceph/mon2/var/lib/ceph/:/var/lib/ceph/ \
	-v /myceph/mon2/var/log/ceph/:/var/log/ceph/ \
	ceph/daemon mon
