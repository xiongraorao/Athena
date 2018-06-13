# Athena
基于 ubuntu 16.04 的 kubernetes (k8s) 的安装、应用实践

---
***Warning:***
老版本的安装方法，使用ubuntu 14 的upstart 创建自启动进程，不推荐
[ubuntu 14.04 + k8s 1.6.3 安装说明](docs/old.md)

# 1 介绍

该项目提供了一种快速上手k8s的安装、应用实践教程

[参考引用](docs/reference.md)

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
- 安装自动化部署程序：[ansible](http://weiweidefeng.blog.51cto.com/1957995/1895261)

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

9. ansible 自动化管理工具

ansible是一个自动化管理工具，可以一键在多机器上面执行命令，适合集群管理。安装ansible之前需要保证集群的SSH免密码链接

``` bash
sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible
```

## 2.2 安装

``` bash
su root
git clone https://github.com/xiongraorao/kubeasz.git
cp -r kubeasz/* /etc/ansible/ && cd /etc/ansible/
git pull origin dev
git checkout dev
# 一键安装
ansible-playbook 90.setup.yml
# 分步骤安装请看readme

```

3. 启动k8s

``` bash
# 默认是开机自启动的，可以根据需要自行修改
sh start_all.sh
```

3. 关闭k8s

``` bash
sh shutdown_all.sh
```

# 2.3.4 手动更新k8s

``` bash
ansible-playbook -t upgrade_k8s 22.upgrade.yml
```


# 3 安装k8s插件

分布式存储方案（支持动态PV)  
- [nfs](https://github.com/xiongraorao/kubeasz/blob/master/docs/guide/nfs-client.md)

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

[kubeasz-jenkins](https://github.com/xiongraorao/kubeasz/blob/master/docs/guide/jenkins.md)
[jenkins持续集成](https://jimmysong.io/kubernetes-handbook/practice/jenkins-ci-cd.html)

install:

1. docker

docker run \
  -u root \
  --rm \  
  -d \ 
  -p 8089:8080 \ 
  -p 50000:50000 \ 
  -v jenkins-data:/var/jenkins_home \ 
  -v /var/run/docker.sock:/var/run/docker.sock \ 
  jenkinsci/blueocean:1.5.0


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
kubectl create -f yaml/poseidon/mysql/
```

## 4.3 Zookeeper高可用安装

```bash
kubectl create -f yaml/poseidon/zookeeper/
```

## 4.4 Kafka高可用安装

```bash
kubectl create -f yaml/poseidon/kafka/
```

## 4.5 seaweedfs高可用安装

```bash
kubectl create -f yaml/poseidon/seaweedfs/
```


# 5 常见错误

1. [socat 和 nsenter not found, 执行 kuberctl  port_forward 会发生该错误](https://github.com/kubernetes/helm/issues/966)

# 6. 学习心得

> k8s1.5之后的版本支持动态分配PV和PVC，使用storage class对象来完成动态PV和PVC的分配，对于有状态的应用是十分友好的，便于扩展。参考链接：[glusterfs 作为provisioner](https://jimmysong.io/kubernetes-handbook/practice/using-heketi-gluster-for-persistent-storage.html) [部署zookeeper](https://github.com/kubernetes/contrib/tree/master/statefulsets/zookeeper)
