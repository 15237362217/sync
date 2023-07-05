#!/bin/bash

sudo docker stop $(sudo docker ps -a -q)
sudo docker rm $(sudo docker ps -a -q)

sudo docker network create --driver bridge --subnet 172.20.0.0/16 ceph-network
sudo docker network list
sudo docker network inspect ceph-network

sudo rm -rf /myceph/*
sudo sh mon1.sh
sudo sh mon2.sh
sudo sh mon3.sh
sudo docker exec  monnode ceph auth get client.bootstrap-osd -o /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo sh osd1.sh
sudo sh osd2.sh
sudo sh osd3.sh
sudo sh mgr.sh
sudo docker exec monnode ceph auth get client.bootstrap-rgw -o /var/lib/ceph/bootstrap-rgw/ceph.keyring
sudo sh rgw.sh
sudo docker exec monnode ceph -s
echo "container create done"
