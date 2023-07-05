#!/bin/bash

sudo docker run -itd \
	--privileged=true \
	--name osdnode3 \
	--network ceph-network \
	--ip 172.20.0.23 \
	-e CLUSTER=ceph \
	-e WEIGHT=1.0 \
	-e MON_NAME=monnode \
	-e MON_IP=172.20.0.11 \
	-v /myceph/etc/ceph:/etc/ceph \
	-v /myceph/var/lib/ceph/:/var/lib/ceph/ \
	-v /myceph/var/lib/ceph/osd/3:/var/lib/ceph/osd \
	-e OSD_TYPE=directory \
	-v /etc/localtime:/etc/localtime:ro \
	ceph/daemon osd

