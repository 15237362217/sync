## centos下使用ceph作为openstack的统一存储解决方案

### 1. 统一存储解决方案

OpenStack 使用 Ceph 作为后端存储可以带来以下好处：

- 不需要购买昂贵的商业存储设备，降低 OpenStack 的部署成本
- Ceph 同时提供了块存储、文件系统和对象存储，能够完全满足 OpenStack 的存储类型需求
- RBD COW 特性支持快速的并发启动多个 OpenStack 实例
- 为 OpenStack 实例默认的提供持久化卷
- 为 OpenStack 卷提供快照、备份以及复制功能
- 为 Swift 和 S3 对象存储接口提供了兼容的 API 支持

**在生产环境中，可以将 Nova、Cinder、Glance 与 Ceph RBD 进行对接。除此之外，还可以将 Swift、Manila 分别对接到 Ceph RGW 与 CephFS。Ceph 作为统一存储解决方案，有效降低了 OpenStack 云环境的复杂性与运维成本。**

### 2. 环境准备

#### 2.1 openstack搭建

centos环境下安装open stack可以参考梓奎的环境[搭建文档]([登录 - Confluence](http://confluence.eswincomputing.com/pages/viewpage.action?pageId=98842403))。

安装完成后，source下keystone_admin，执行以下命令检测核心组件命令行是否能正常调用。

1、出现下方内容说明openstack系列命令可正常使用。

![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-07-07-15-36-38-image.png)

2、检查glance命令，无报错即可。

![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-06-28-16-03-56-image.png)

3、检查nova命令，无报错即可

![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-06-28-16-04-35-image.png)

4、检查cinder命令，无报错即可

![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-06-28-16-05-01-image.png)

openstack环境检查完毕后，可以登录dashboard界面参考官网教程上传镜像并创建实例，如果实例可以正常运行，则openstack环境搭建已经OK。

#### 2.2 ceph集群搭建

ceph集群搭建可以参考海俊哥的环境[搭建文档]([登录 - Confluence](http://confluence.eswincomputing.com/pages/viewpage.action?pageId=101265302))。

在上面ceph集群部署文档中的脚本基础上进行优化，增加shell脚本可以快速在docker中搭建起ceph集群。

mgr节点

```shell
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
```

mon1节点

```shell
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
```

mon2节点

```shell
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
```

mon3节点

```shell
#!/bin/bash
sudo docker run -itd \
    --privileged=true \
    --name monnode3 \
    --ip 172.20.0.13 \
    --network ceph-network \
    -e CLUSTER=ceph \
    -e WEIGHT=1.0 \
    -e MON_NAME=monnode3 \
    -e MON_IP=172.20.0.13 \
    -e CEPH_PUBLIC_NETWORK=172.20.0.0/16 \
    -v /myceph/mon3/etc/ceph:/etc/ceph \
    -v /myceph/mon3/var/lib/ceph/:/var/lib/ceph/ \
    -v /myceph/mon3/var/log/ceph/:/var/log/ceph/ \
    ceph/daemon mon
```

osd1节点

```shell
#!/bin/bash

sudo docker run -itd \
    --privileged=true \
    --name osdnode1 \
    --network ceph-network \
    --ip 172.20.0.21 \
    -e CLUSTER=ceph \
    -e WEIGHT=1.0 \
    -e MON_NAME=monnode \
    -e MON_IP=172.20.0.11 \
    -v /myceph/etc/ceph:/etc/ceph \
    -v /myceph/var/lib/ceph/:/var/lib/ceph/ \
    -v /myceph/var/lib/ceph/osd/1:/var/lib/ceph/osd \
    -e OSD_TYPE=directory \
    -v /etc/localtime:/etc/localtime:ro \
    ceph/daemon osd
```

osd2节点

```shell
#!/bin/bash

sudo docker run -itd \
    --privileged=true \
    --name osdnode2 \
    --network ceph-network \
    --ip 172.20.0.22 \
    -e CLUSTER=ceph \
    -e WEIGHT=1.0 \
    -e MON_NAME=monnode \
    -e MON_IP=172.20.0.11 \
    -v /myceph/etc/ceph:/etc/ceph \
    -v /myceph/var/lib/ceph/:/var/lib/ceph/ \
    -v /myceph/var/lib/ceph/osd/2:/var/lib/ceph/osd \
    -e OSD_TYPE=directory \
    -v /etc/localtime:/etc/localtime:ro \
    ceph/daemon osd
```

osd3节点

```shell
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
```

rgw节点

```shell
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
```

ceph集群一键部署脚本

```shell
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
```

ceph集群创建完成后可使用下方脚本开启mgr节点的dashboard界面。该脚本有可能首次执行配置无效，可以多执行几次，直至出现有效的dashboard网页连接。

```shell
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
```

至此，docker中ceph集群已经部署好。

![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-06-28-16-03-39-image.png)

。![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-06-28-15-58-04-image.png)

#### 2.3 ceph客户端安装

安装ceph客户端并对接ceph集群

```shell
yum install python-rbd
yum install ceph-common
```

ceph-common客户端的默认安装路径为/etc/ceph

将前面docker中ceph集群的挂载目录中的ceph. conf文件拷贝至/etc/ceph中，即可通过ceph客户端访问docker中的ceph集群。

![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-06-28-16-06-30-image.png)

### 3 openstack glance&cinder&nova对接ceph RBD块存储

#### 3.1背景介绍

![](https://upload-images.jianshu.io/upload_images/16952149-d827b243864b8d87.png?imageMogr2/auto-orient/strip|imageView2/2/w/1200/format/webp)

**glance** 作为openstack中镜像服务，支持多种适配器，支持将镜像存放到本地文件系统，http服务器，ceph分布式文件系统，glusterfs和sleepdog等开源的分布式文件系统上，本文，通过将讲述glance如何和ceph结合。

目前glance采用的是本地filesystem的方式存储，存放在默认的路径`/var/lib/glance/images`下，当把本地的文件系统修改为分布式的文件系统ceph之后，原本在系统中镜像将无法使用，所以建议当前的镜像删除，部署好ceph之后，再统一上传至ceph中存储。

**nova** 负责虚拟机的生命周期管理，包括创建，删除，重建，开机，关机，重启，快照等，作为openstack的核心，nova负责IaaS中计算重要的职责，其中nova的存储格外重要，默认情况下，nova将instance的数据存放在/var/lib/nova/instances/%UUID目录下，使用本地的存储空间。使用这种方式带来的好处是:简单，易实现，速度快，故障域在一个可控制的范围内。然而，缺点也非常明显：compute出故障，上面的虚拟机down机时间长，没法快速恢复，此外，一些特性如热迁移live-migration,虚拟机容灾nova evacuate等高级特性，将无法使用，对于后期的云平台建设，有明显的缺陷。对接 Ceph 主要是希望将实例的系统磁盘文件储存到 Ceph 集群中。与其说是对接 Nova，更准确来说是对接 QEMU-KVM/libvirt，因为 librbd 早已原生集成到其中。

**Cinder** 为 OpenStack 提供卷服务，支持非常广泛的后端存储类型。对接 Ceph 后，Cinder 创建的 Volume 本质就是 Ceph RBD 的块设备，当 Volume 被虚拟机挂载后，Libvirt 会以 rbd 协议的方式使用这些 Disk 设备。除了 cinder-volume 之后，Cinder 的 Backup 服务也可以对接 Ceph，将备份的 Image 以对象或块设备的形式上传到 Ceph 集群。

#### 3.2 对接准备

验证 Ceph Storage 集群是否正在运行，并处于 `HEALTH_OK` 状态：

```shell
ceph -s
```

创建ceph池并进行rbd初始化

```shell
ceph osd pool create volumes 32
rbd pool init volumes
ceph osd pool create images 32
rbd pool init images
ceph osd pool create vms 32
rbd pool init vms
```

配置 Ceph 客户端身份验证

从 Ceph 客户端，为 Cinder、Cinder Backup 和 Glance 创建新用户：

```shell
ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'
ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
```

为 `client.cinder`、`client.glance` 生成密钥：

```shell
ceph auth get-or-create client.cinder -o /etc/ceph/ceph.client.cinder.keyring

ceph auth get-or-create client.glance -o /etc/ceph/ceph.client.glance.keyring
```

将 `client.cinder` 用户的机密密钥存储在 `libvirt` 中。

```shell
ceph auth get-key client.cinder -o client.cinder.key
```

为 secret 生成 UUID，并保存 secret 的 UUID

```shell
uuidgen > uuid-secret.txt
```

将 secret 密钥添加到 `libvirt` 中

```shell
cat > secret.xml <<EOF
<secret ephemeral='no' private='no'>
  <uuid>`cat uuid-secret.txt`</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>
EOF
```

为 `libvirt` 设置并定义 secret：

```shell
virsh secret-define --file secret.xml
virsh secret-set-value --secret $(cat uuid-secret.txt) --base64 $(cat client.cinder.key) && rm client.cinder.key secret.xml
```

#### 3.3配置cinder使用ceph块设备

修改配置cinder配置文件

```shell
vim /etc/cinder/cinder.conf
```

在 `[DEFAULT]` 部分中，启用 Ceph 作为 Cinder 的后端,确保 Glance API 版本设置为 2

```shell
[DEFAULT]
enabled_backends = ceph
glance_api_version = 2
```

在 `cinder.conf` 文件中创建 `[ceph]` 部分。在 `[ceph]` 部分下的下列步骤中添加 Ceph 设置。

```shell
[ceph]
volume_driver = cinder.volume.drivers.rbd.RBDDriver
rbd_cluster_name = ceph
rbd_pool = volumes
rbd_user = cinder
rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_flatten_volume_from_snapshot = false
rbd_secret_uuid = 4b5fd580-360c-4f8c-abb5-c83bb9a3f964
rbd_max_clone_depth = 5
rbd_store_chunk_size = 4
rados_connect_timeout = -1
```

#### 3.4配置glance使用ceph块设备

编辑 `/etc/glance/glance-api.conf` 文件。

```shell
vim /etc/glance/glance-api.conf
```

```shell
stores = rbd
default_store = rbd
rbd_store_chunk_size = 8
rbd_store_pool = images
rbd_store_user = glance
rbd_store_ceph_conf = /etc/ceph/ceph.conf
```

要启用写时复制(CoW)克隆，将 `show_image_direct_url` 设置为 `True`。

```shell
show_image_direct_url = True
```

如有必要，禁用缓存管理。`该类别` 应仅设置为 `keystone`，而不应设置为 `keystone+cachemanagement`。

```shell
flavor = keystone
```

#### 3.5配置nova使用ceph块设备

编辑 Ceph 配置文件：

```shell
vim /etc/ceph/ceph.conf
```

将以下部分添加到 Ceph 配置文件的 `[client]` 部分：

```shell
[client]
rbd cache = true
rbd cache writethrough until flush = true
rbd concurrent management ops = 20
admin socket = /var/run/ceph/guests/$cluster-$type.$id.$pid.$cctid.asok
log file = /var/log/ceph/qemu-guest-$pid.log
```

为 admin socket 和日志文件创建新目录，并更改目录权限以使用 `qemu` 用户和 `libvirtd` 组：

```shell
mkdir -p /var/run/ceph/guests/ /var/log/ceph/
chown qemu:libvirt /var/run/ceph/guests /var/log/ceph/
```

编辑 `/etc/nova/nova.conf` 文件。在 `[libvirt]` 部分下，配置以下设置：

```shell
[libvirt]
images_type = rbd
images_rbd_pool = vms
images_rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_user = cinder
rbd_secret_uuid = 4b5fd580-360c-4f8c-abb5-c83bb9a3f964
disk_cachemodes="network=writeback"
inject_password = false
inject_key = false
inject_partition = -2
live_migration_flag="VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST,VIR_MIGRATE_TUNNELLED"
hw_disk_discard = unmap
```

注：将 `rbd_user_secret` 中的 UUID 替换为 `uuid-secret.txt` 文件中的 UUID。

#### 3.6重启openstack服务

重启适当的 OpenStack 服务：

```shell
systemctl restart openstack-cinder-volume
systemctl restart openstack-cinder-backup
systemctl restart openstack-glance-api
systemctl restart openstack-nova-compute
```

#### 3.7对接检验

##### glance对接检验

对接完成可以执行下方命令上传镜像进行测试

```shell
glance image-create --name cirros --disk-format raw --container-format ovf --f {your-image-path}
```

镜像上传完成后可以检查是否成功

![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-06-28-16-28-40-image.png)

openstack的dashboard界面也可以看到上传的镜像

![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-06-28-16-29-10-image.png)

镜像上传成功则说明，glance对接完成。

##### cinder对接检验

通过 Cinder 命令创建一个空白盘

```shell
cinder create --display-name {volume-name} {volume-size}
```

查询cinder存储池信息，查看所创建的空白盘是否已承载在ceph

```shell
rbd ls volumes
```

![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-06-28-16-33-27-image.png)

![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-06-28-16-33-36-image.png)

##### ceph检验

ceph客户端检验

![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-06-28-16-35-30-image.png)

ceph的dashboard检验

![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-06-28-16-35-47-image.png)
##### nova检验
openstack image  list查看可用镜像
openstack network list查看可用网络
openstack flavor list查看类型
```shell
openstack server create --image cirros-ceph --flavor m1.tiny --nic net-id=network-uuid nova-ceph-test
```
# 

### 4 openstack swift对接ceph RGW对象存储

![](C:\Users\e0005105\AppData\Roaming\marktext\images\2023-07-07-14-30-16-18224821844680859278.jpg)

centos下安装的train版openstack已经集成了swift，开箱即用。登录dashboard界面就可以看到对象存储，创建容器后即可使用。

swift本身就是一个对象存储系统，而ceph也能提供对象存储且ceph rgw又兼容swift api，如果需要由ceph提供后端存储，可以将swift对接至ceph rgw。

参考文章：[配置openstack swift使用ceph作为后端存储](https://www.rhce.cc/2806.html)（仅供参考，并未验证）

### 5 openstack manila对接cephFs文件存储

参考文章：[开源技术实践分享：Manila + Cephfs 调研-51CTO.COM](https://www.51cto.com/article/558873.html)（仅供参考，并未验证）
