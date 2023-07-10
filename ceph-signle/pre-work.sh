#!/bin/bash

yum -y install python-rbd
yum -y install ceph-common 

cd /myceph/etc/ceph
cp * /etc/ceph
ceph df


ceph osd pool create volumes 32
rbd pool init volumes
ceph osd pool create images 32
rbd pool init images
ceph osd pool create vms 32
rbd pool init vms


ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'
ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'


ceph auth get-or-create client.cinder -o /etc/ceph/ceph.client.cinder.keyring
ceph auth get-or-create client.glance -o /etc/ceph/ceph.client.glance.keyring

ceph auth get-key client.cinder -o client.cinder.key
uuidgen > uuid-secret.txt


cat > secret.xml <<EOF
<secret ephemeral='no' private='no'>
  <uuid>`cat uuid-secret.txt`</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>
EOF

virsh secret-define --file secret.xml
virsh secret-set-value --secret $(cat uuid-secret.txt) --base64 $(cat client.cinder.key)