# Athena
基于 ubuntu 14.04 的 kubernetes (k8s) 的安装、应用实践

---

# 1 介绍

该项目提供了一种快速上手k8s的安装、应用实践教程

## 1.1 参考引用

1. 文档类
- [k8s官方文档](https://kubernetes.io/docs/concepts/)
- [kubernetes-handbook(非常全面,强烈推荐)](https://jimmysong.io/kubernetes-handbook/)
- [k8s中文文档](https://www.kubernetes.org.cn/k8s)

2. 安装方法类
- [Vernlium-k8s安装步骤](https://vernlium.github.io/2017/08/16/kubernetes%E5%9F%BA%E6%9C%AC%E5%AE%89%E8%A3%85-k8s-3/)
- [Vernlium-flannel安装步骤](https://vernlium.github.io/2017/09/19/flannel%E4%BB%8B%E7%BB%8D%E5%8F%8A%E5%AE%89%E8%A3%85-k8s-7/)
- [国内网络环境获取gcr.io/google-containers镜像的方法](https://www.linuxidc.com/Linux/2018-02/151015.htm)
- [linux-upstart](http://blog.fens.me/linux-upstart/)
- [etcd集群部署的坑](https://www.cnblogs.com/breg/p/5728237.html)
- [etcd集群安装配置](https://blog.csdn.net/god_wot/article/details/77854093)
- [使用kube-proxy让外部网络访问K8S service的ClusterIP](https://blog.csdn.net/liyingke112/article/details/76022267)
- [k8s 安装 heketi服务动态使用GlusterFS](https://blog.csdn.net/wenwenxiong/article/details/79530631)
- [glusterfs + heketi实现kubernetes的共享存储](http://www.mamicode.com/info-detail-2258744.html)
- [在kubernetes集群中部署mysql主从](http://blog.51cto.com/ylw6006/2071864)

3. kubernetes中文社区
- [kubeadm安装Kubernetes V1.10集群详细文档](https://www.kubernetes.org.cn/3808.html)
- [Kubernetes v1.10.x HA 全手动安装教程(TL;DR)](https://www.kubernetes.org.cn/3814.html)

4. 其他文档
- [Linux shell字符串截取与拼接](https://www.linuxidc.com/Linux/2015-03/115198.htm)
- [linux shell 数组建立及使用技巧](https://www.cnblogs.com/chengmo/archive/2010/09/30/1839632.html)
- [Kubernetes vs Docker Swarm](https://platform9.com/blog/kubernetes-docker-swarm-compared/)
- [巅峰对决之Swarm、Kubernetes、Mesos](http://dockone.io/article/1138)
- [Docker Swarm和Kubernetes在大规模集群中的性能比较](http://dockone.io/article/1145)
- [Docker Swarm vs Kubernetes](http://dockone.io/article/2441)
- [Kubernetes为什么很重要？](http://cnodejs.org/topic/576a3305d0aa704d0728ac7e)
- [持久卷PV和PVC的使用](http://www.cnblogs.com/boshen-hzb/p/6519902.html)
- [CentOS 7 安装 GlusterFS](http://www.cnblogs.com/jicki/p/5801712.html)
- [pv 和 pvc的绑定](https://docs.openshift.org/latest/install_config/persistent_storage/selector_label_binding.html)

# 2 安装运行
## 2.1 准备工作

**以下操作需要在所有节点执行**

- 设置/etc/hosts 解析
- [集群节点ssh免密码连接](https://xiongraorao.github.io/2017/02/17/ssh%E5%85%8D%E5%AF%86%E7%A0%81%E7%99%BB%E5%BD%95/)
- [集群时间同步](https://xiongraorao.github.io/2017/04/25/linux%E6%9C%8D%E5%8A%A1%E5%99%A8%E6%97%B6%E9%97%B4%E5%90%8C%E6%AD%A5/)
- 关闭、禁用所有节点的防火墙
- [安装docker-ce](https://mirrors.tuna.tsinghua.edu.cn/help/docker-ce/)
- 禁用交换内存(k8s version 1.8+ )
- 设置允许路由转发，不对bridge的数据进行处理 

1. 设置/etc/hosts解析

下文均按此示例操作：

ip地址 | 主机名 | 备注
--- | --- | --- 
192.168.1.3 | cloud03 | workerNode
192.168.1.5 | cloud05 | masterNode workerNode
192.168.1.6 | cloud06 | workerNode

``` bash
ssh root@192.168.1.5
cat >> /etc/hosts << EOF
192.168.1.3    cloud03
192.168.1.5    cloud05
192.168.1.6    cloud06
EOF
for ip in 3 6;do scp /etc/hosts root@192.168.1.$ip:/etc/;done
```

2. ssh 免密码链接
``` bash
ssh root@192.168.1.5
ssh-keygen -t rsa 
# 一路回车
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# 在其他节点重复以上操作
# 复制集群其他节点的id_rsa.pub文件到~/.ssh/authorized_keys
for ip in 3 6;do scp root@192.168.1.$ip:/root/.ssh/id_rsa.pub ./$ip.pub;done
for ip in 3 6;do cat ./$ip.pub >> ~/.ssh/authorized_keys;done
# 分发公钥
for ip in 3 6;do scp ~/.ssh/authorized_keys root@192.168.1.$ip:/root/.ssh/;done
```

3. [集群时间同步](https://xiongraorao.github.io/2017/04/25/linux%E6%9C%8D%E5%8A%A1%E5%99%A8%E6%97%B6%E9%97%B4%E5%90%8C%E6%AD%A5/)

4. 关闭、禁用所有节点的防火墙

``` bash
ssh root@192.168.1.5
service ufw stop
#检查一下
service ufw status
# 确认是否是inactive
# 去其他节点重复操作
```

5. 安装docker-ce

[官方ubuntu docker安装文档](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
[清华镜像安装(推荐)]((https://mirrors.tuna.tsinghua.edu.cn/help/docker-ce/))

``` bash
# 安装依赖
sudo apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
# 添加GPG公钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# ubuntu amd64
sudo add-apt-repository \
   "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
# 不能安装太高的，否则可能导致kubelet无法启动
sudo apt-get install docker-ce=17.03.0~ce-0~ubuntu-trusty

```

6. 禁用交换内存(k8s version 1.8+ )

``` bash
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab
```

7. 设置允许路由转发，不对bridge的数据进行处理 

``` bash
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p /etc/sysctl.d/k8s.conf
```

## 2.2 安装环境依赖

**以下步骤在所有节点上执行**

### 2.2.1 etcd 服务

``` bash
wget -c https://github.com/coreos/etcd/releases/download/v3.2.20/etcd-v3.2.20-linux-amd64.tar.gz
tar -xvzf etcd-v3.2.20-linux-amd64.tar.gz
mv etcd-v3.2.20-linux-amd64/etcd* /usr/local/bin

# check
which etcd
/usr/local/bin/etcd
```

### 2.2.2 flannel 服务

``` bash
wget -c https://github.com/coreos/flannel/releases/download/v0.10.0/flannel-v0.10.0-linux-amd64.tar.gz
tar -xvzf flannel-v0.10.0-linux-amd64.tar.gz
mv flanneld /usr/local/bin/
mv mk-docker-opts.sh /usr/local/bin/

# check
which flanneld
/usr/local/bin/flanneld
```

### 2.2.3 keepalived 服务

``` bash
apt-get install -y keepalived haproxy ipvsadm
```
[后续参考步骤](https://jimmysong.io/kubernetes-handbook/practice/master-ha.html)

### 2.2.4 GlusterFS 服务

1. [基于node本地安装](https://jimmysong.io/kubernetes-handbook/practice/using-glusterfs-for-persistent-storage.html)
2. [基于k8s安装](https://github.com/gluster/gluster-kubernetes/blob/master/docs/setup-guide.md)

[centos7安装glusterfs](http://www.cnblogs.com/jicki/p/5801712.html)

### 2.2.5 ansible 自动化工具

ansible是一个自动化管理工具，可以一键在多机器上面执行命令，适合集群管理。安装ansible之前需要保证集群的SSH免密码链接

```bash
sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible

# 下面all组的该为真实的集群主机名
cat > /etc/ansible/hosts << EOF
[all]
cloud03
cloud05
cloud06
EOF

# test,显示success说明已经ansible配置成功
ansible all -m ping

cloud05 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
cloud03 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
cloud06 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}

```

## 2.3 安装步骤


### 2.3.1 安装k8s相关组件

**以下步骤均在master节点执行**

创建/etc/kubernetest/ssl目录，命令如下

		ansible all -m shell -a "mkdir -p /etc/kubernetes/ssl"

``` bash
# 可根据需要自行选择安装k8s的版本，注意k8s 1.8版本及以上的需要安装
wget -c https://dl.k8s.io/v1.8.12/kubernetes-server-linux-amd64.tar.gz
# sha256hash: c2afbabf2e172ce7cd6a58b314d2e82e0cd6d42955a3a807567c785bbab9fea6
# 验证hash
sha256sum kubernetes-server-linux-amd64.tar.gz
c2afbabf2e172ce7cd6a58b314d2e82e0cd6d42955a3a807567c785bbab9fea6  kubernetes-server-linux-amd64.tar.gz

tar -xvzf kubernetes-server-linux-amd64.tar.gz
cd kubernetes
cp -r server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kube-proxy,kubelet} /usr/local/bin/
# 分发到其他workder node上去
for ip in 3 6;do scp -r server/bin/{kube-proxy,kubelet} root@192.168.1.$ip:/usr/local/bin/;done

```

### 2.3.2 生成CA文件

需要生成的CA证书和秘钥文件如下：
- ca-key.pem
- ca.pem
- kubernetes-key.pem
- kubernetes.pem
- kube-proxy.pem
- kube-proxy-key.pem
- admin.pem
- admin-key.pem

使用的证书文件如下：
- etcd：使用 ca.pem、kubernetes-key.pem、kubernetes.pem；
- kube-apiserver：使用 ca.pem、kubernetes-key.pem、kubernetes.pem；
- kubelet：使用 ca.pem；
- kube-proxy：使用 ca.pem、kube-proxy-key.pem、kube-proxy.pem；
- kubectl：使用 ca.pem、admin-key.pem、admin.pem；
- kube-controller-manager：使用 ca-key.pem、ca.pem

详细步骤：
[创建TLS证书和秘钥](https://jimmysong.io/kubernetes-handbook/practice/create-tls-and-secret-key.html)

一键生成CA文件：

``` bash
# 安装CFSSL
./get_cfssl.sh

# 生成CA证书和秘钥文件
./generate_ssl.sh 192.168.1.3 192.168.1.5 192.168.1.6

```

# 2.3.2 启动k8s

1. 生成upstart脚本和相应配置文件

``` bash
su root
git clone https://github.com/xiongraorao/Athena.git
cd Athena
./configure 192.168.1.5 192.168.1.3 192.168.1.5 192.168.1.6
```

2. 生成SSL证书文件

需要生成的CA证书和秘钥文件如下：
- ca-key.pem
- ca.pem
- kubernetes-key.pem
- kubernetes.pem
- kube-proxy.pem
- kube-proxy-key.pem
- admin.pem
- admin-key.pem

使用的证书文件如下：
- etcd：使用 ca.pem、kubernetes-key.pem、kubernetes.pem；
- kube-apiserver：使用 ca.pem、kubernetes-key.pem、kubernetes.pem；
- kubelet：使用 ca.pem；
- kube-proxy：使用 ca.pem、kube-proxy-key.pem、kube-proxy.pem；
- kubectl：使用 ca.pem、admin-key.pem、admin.pem；
- kube-controller-manager：使用 ca-key.pem、ca.pem

详细步骤：
[创建TLS证书和秘钥](https://jimmysong.io/kubernetes-handbook/practice/create-tls-and-secret-key.html)

一键生成CA文件：

``` bash
# 安装CFSSL
./get_cfssl.sh

# 生成CA证书和秘钥文件
./generate_ssl.sh 192.168.1.3 192.168.1.5 192.168.1.6

```


3. 启动k8s

``` bash
# 每个节点执行
start etcd

# 生成kubeconfig文件
./kubeconfig.sh 192.168.1.5 192.168.1.3 192.168.1.5 192.168.1.6

# 配置flanneld, 后面接的参数可以是etcd 任一节点的IP
ansible all -m shell -a "./flanneld_config.sh 192.168.1.5"

# 检查各个节点的docker daemon 是否完全重启成功
# 检查docker0 和 flannl.1 的地址是否在同一个网段
ifconfig docker0
ifconfig flannel.1

# 主节点配置kubernetes cluster的各种参数
./kubeconfig.sh

# 主节点查看kubelet请求

kubectl get csr
# csr-xxx

# 主节点同意kublet 请求

kubectl certificate approve csr-xxx

```
注意：如果master 无法发现kubelet 的注册请求，请查看相应节点的kubelet 服务的运行状态
```bash
# 1. 查看kubelet节点运行状态
status kubelet

# 2. 如果显示stop/waiting
start kubelet
tailf /var/log/upstart/kubelet.log

# 3. 检查node节点状态
kubectl get nodes 

# 4. 如果节点状态是NotReady
kubectl describe nodes

# 5. 检查docker daemon 服务
cat /etc/default/docker # 查看DOCKER_OPTS变量是否配置正确，参考flanneld配置部分
service docker restart
docker info
docker ps
```

3. 关闭k8s

``` bash
# 每个节点执行
stop etcd

```

# 2.3.4 手动更新k8s

[升级步骤](https://jimmysong.io/kubernetes-handbook/practice/manually-upgrade.html)


# 3 安装k8s插件

## 3.1 dashboard控制面板

[dashboard v1.6.0](https://jimmysong.io/kubernetes-handbook/practice/dashboard-addon-installation.html)
[dashboard v1.7.1安装步骤](https://jimmysong.io/kubernetes-handbook/practice/dashboard-upgrade.html)

## 3.2 kubedns 插件
[kube dns插件安装](https://jimmysong.io/kubernetes-handbook/practice/kubedns-addon-installation.html)

## 3.3 heapster集群应用监控插件

[heapster插件](https://jimmysong.io/kubernetes-handbook/practice/heapster-addon-installation.html)

## 3.4 traefik负载均衡插件

[trafix ingress安装步骤](https://jimmysong.io/kubernetes-handbook/practice/traefik-ingress-installation.html)

traefik高可用的配置：
```bash
apt-get install keepalived ipvsadm
vim /etc/keepalived/keepalived.conf

# 配置virtual_server 和real_server, 保证virtual_server 是局域网中一个可用的ip

for ip in seq 3 5 6; do scp conf/keepalived-master.conf root@192.168.1.$ip:/etc/keepalived/; done

```
> *注意，如果node的80端口被占用的话，会导致启动traefik失败*

## 3.5 Helm服务编排插件

[helm管理插件](https://jimmysong.io/kubernetes-handbook/practice/helm.html)

此处有个坑，要求每个node必须安装好socat和nsenter [github issue](https://github.com/kubernetes/helm/issues/966)
解决如下：
```bash
# 1. install socat
sudo apt-get update && sudo apt-get install socat

# 2. install nsenter
cd /tmp; 
curl https://www.kernel.org/pub/linux/utils/util-linux/v2.25/util-linux-2.25.tar.gz | tar -zxf-; cd util-linux-2.25;
sudo apt-get install autopoint autoconf libtool automake
./configure --without-python --disable-all-programs --enable-nsenter --without-ncurses
make nsenter
cp nsenter /usr/local/bin
```

## 3.6 Jenkins(gitlab)持续集成插件

[jenkins持续集成](https://jimmysong.io/kubernetes-handbook/practice/jenkins-ci-cd.html)


## 3.7 Drone(github)持续集成插件

[drone持续集成](https://jimmysong.io/kubernetes-handbook/practice/drone-ci-cd.html)

## 3.8 Master节点高可用安装

[keepalived+haproxy方案](https://jimmysong.io/kubernetes-handbook/practice/master-ha.html)

# 4 部署应用

## 4.1 nginx安装

```bash
cd yaml/nginx/
kubectl create -f .
```

## 4.2 Mysql高可用安装

```bash
cd yaml/mysql/
./gluster_mysql.sh
kubectl create -f .
```

## 4.3 Zookeeper高可用安装
默认三个节点，如果需要增加节点，需要手动修改gluster_zk.sh文件, 增加volumes,也需要手动增加pv和pvc

```bash
cd yaml/zookeeper/
./gluster_zk.sh
kubectl create -f .
```
## 4.4 Kafka高可用安装
默认三个节点，如果需要增加节点，需要手动修改gluster_kafka.sh文件, 增加volumes,也需要手动增加pv和pvc
```bash
cd yaml/kafka/
./gluster_kafka.sh
kubectl create -f .
```
## 4.5 seaweedfs高可用安装
默认三个节点，如果需要增加节点，需要手动修改gluster_seaweedfs.sh文件, 增加volumes,也需要手动增加pv和pvc
```bash
cd yaml/seaweedfs/
./gluster_seaweedfs.sh
kubectl create -f .
```


# 5 常见错误

1. [socat 和 nsenter not found, 执行 kuberctl  port_forward 会发生该错误](https://github.com/kubernetes/helm/issues/966)

# 6. 学习心得

> k8s1.5之后的版本支持动态分配PV和PVC，使用storage class对象来完成动态PV和PVC的分配，对于有状态的应用是十分友好的，便于扩展。参考链接：[glusterfs 作为provisioner](https://jimmysong.io/kubernetes-handbook/practice/using-heketi-gluster-for-persistent-storage.html) [部署zookeeper](https://github.com/kubernetes/contrib/tree/master/statefulsets/zookeeper)

