#!/bin/bash

sudo docker run -itd \
	--privileged=true \
	--restart=always \
	--name mgrnode \
	--network ceph-network \
	--ip 172.20.0.5 \
	-e CLUSTER=ceph \
	--pid=container:monnode \
	-v /myceph/etc/ceph:/etc/ceph \
	-v /myceph/var/lib/ceph/:/var/lib/ceph/ \
	-p 18080:18080 \
	ceph/daemon mgr

