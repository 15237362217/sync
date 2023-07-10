#!/bin/bash
uname -r 

yum -y update

yum install -y yum-utils device-mapper-persistent-data lvm2

yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

yum list docker-ce --showduplicates | sort -r

yum -y install docker-ce

systemctl start docker
systemctl enable docker


