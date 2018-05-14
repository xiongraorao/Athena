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

3. kubernetes中文社区
- [kubeadm安装Kubernetes V1.10集群详细文档](https://www.kubernetes.org.cn/3808.html)
- [Kubernetes v1.10.x HA 全手动安装教程(TL;DR)](https://www.kubernetes.org.cn/3814.html)

4. 其他文档
- [Linux shell字符串截取与拼接](https://www.linuxidc.com/Linux/2015-03/115198.htm)
- [linux shell 数组建立及使用技巧](https://www.cnblogs.com/chengmo/archive/2010/09/30/1839632.html)
- []()


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
apt-get install -y keepalived haproxy
```
[后续参考步骤](https://jimmysong.io/kubernetes-handbook/practice/master-ha.html)

### 2.2.4 GlusterFS 服务

1. [基于node本地安装](https://jimmysong.io/kubernetes-handbook/practice/using-glusterfs-for-persistent-storage.html)
2. [基于k8s安装](https://github.com/gluster/gluster-kubernetes/blob/master/docs/setup-guide.md)

## 2.3 安装步骤

ssh到所有节点，创建如下两个目录
mkdir -p /etc/kubernetes
mkdir -p /etc/kubernetes/ssl

**以下步骤均在master节点执行**

### 2.3.1 安装k8s相关组件

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

# 生成kubeconfig文件
./kubeconfig.sh 192.168.1.5 192.168.1.3 192.168.1.5 192.168.1.6
```

# 2.3.3 启动k8s

``` bash
# ssh 到集群所有的节点上
mkdir -p /etc/kubernetes/
```
1. 生成配置文件

``` bash
su root
git clone https://github.com/xiongraorao/Athena.git
cd Athena
./config 192.168.1.5 192.168.1.3 192.168.1.5 192.168.1.6
```

2. 启动k8s

``` bash
# 每个节点执行
start etcd

# 配置flanneld
# ssh 到每个节点执行以下命令
./flanneld_config.sh 192.168.1.5

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

## 3.4 trafix负载均衡插件

[trafix ingress安装步骤](https://jimmysong.io/kubernetes-handbook/practice/traefik-ingress-installation.html)

## 3.5 Helm服务编排插件

[helm管理插件](https://jimmysong.io/kubernetes-handbook/practice/helm.html)

## 3.6 Jenkins(gitlab)持续集成插件

[jenkins持续集成](https://jimmysong.io/kubernetes-handbook/practice/jenkins-ci-cd.html)


## 3.7 Drone(github)持续集成插件

[drone持续集成](https://jimmysong.io/kubernetes-handbook/practice/drone-ci-cd.html)

# 4 部署应用

## 4.1 nginx安装

## 4.2 Mysql高可用安装

## 4.3 Zookeeper高可用安装

## 4.4 Kafka高可用安装

