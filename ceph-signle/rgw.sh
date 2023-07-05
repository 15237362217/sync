#!/bin/bash
sudo docker run -itd \
	--privileged=true \
	--name rgwnode \
	--network ceph-network \
	--ip 172.20.0.6 \
	-e CLUSTER=ceph \
	-v /myceph/var/lib/ceph/:/var/lib/ceph/ \
	-v /myceph/etc/ceph:/etc/ceph \
	-v /etc/localtime:/etc/localtime:ro \
	-e RGW_NAME=rgw0 \
	ceph/daemon rgw

