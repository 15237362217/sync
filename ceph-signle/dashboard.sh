#!/bin/bash

# sudo docker exec  mgrnode ceph mgr module enable dashboard

echo user> pwd.txt

sudo docker cp pwd.txt mgrnode:/

sudo docker exec  mgrnode ceph mgr module enable dashboard \
&& docker exec mgrnode ceph dashboard set-login-credentials user -i pwd.txt \
&& docker exec mgrnode ceph config set mgr mgr/dashboard/server_port 18080 \
&& docker exec mgrnode ceph config set mgr mgr/dashboard/server_addr 172.20.0.5 \
&& docker exec mgrnode ceph config set mgr mgr/dashboard/ssl false \
&& docker exec mgrnode ceph mgr services

