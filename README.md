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

- 打通集群间节点的ssh免密码连接
- 集群时间同步(ntp)
- 关闭、禁用所有节点的防火墙
- 设置/etc/hosts 解析
- 安装docker-ce
- 禁用交换内存(k8s version 1.8+ )
- 设置允许路由转发，不对bridge的数据进行处理 

// TODO 设置好以上的内容

## 2.2 安装环境依赖

// TODO 安装k8s的软件依赖包
### 2.2.1 flannel 服务

### 2.2.2 keepalived 服务

### 2.2.3 GlusterFS 服务

## 2.3 安装步骤

// TODO 初始化配置，生成CA，启动服务，关闭服务等

# 3 安装k8s插件

## 3.1 dashboard控制面板

## 3.2 heapster集群应用监控插件

## 3.3 trafix负载均衡插件

## 3.4 Helm服务编排插件

## 3.5 Jenkins(gitlab)持续集成插件

## 3.6 Drone(github)持续集成插件


# 4 部署应用

## 4.1 nginx安装

## 4.2 Mysql高可用安装

## 4.3 Zookeeper高可用安装

## 4.4 Kafka高可用安装

