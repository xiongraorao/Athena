# usage

## Before you start

将cpu和gpu文件夹中的dockerfile文件中的git clone后面的地址中的USERNAME和PASSWORD改为你的远程仓库用户名和密码。

## Prerequisites

- [docker-17](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce-1)
- [nvidia-docker](https://github.com/nvidia/nvidia-docker/wiki/Installation-(version-2.0))

## Depends (nvidia-docker2)
- Depends: nvidia-container-runtime  
- Depends: docker-ce  

### 查询可用版本

```bash
# Use apt-cache madison nvidia-docker2 nvidia-container-runtime to list the available versions
# k8s不支持docker-ce18，所以使用17
# docker-ce
$ apt-cache madison docker-ce 
# results
 docker-ce | 17.09.0~ce-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 17.06.2~ce-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 17.06.1~ce-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
# nvidia-container-runtime
$ apt-cache madison nvidia-container-runtime
# results
 nvidia-container-runtime | 2.0.0+docker17.09.1-1 | https://nvidia.github.io/nvidia-container-runtime/ubuntu14.04/amd64/  Packages
 nvidia-container-runtime | 2.0.0+docker17.06.2-1 | https://nvidia.github.io/nvidia-container-runtime/ubuntu14.04/amd64/  Packages
 nvidia-container-runtime | 2.0.0+docker17.06.2-1 | https://nvidia.github.io/nvidia-container-runtime/ubuntu14.04/amd64/  Packages
# nvidia-docker2
$ apt-cache madison nvidia-docker2
# results
 nvidia-docker2 | 2.0.3+docker17.09.1-1 | https://nvidia.github.io/nvidia-docker/ubuntu14.04/amd64/  Packages
 nvidia-docker2 | 2.0.3+docker17.06.2-1 | https://nvidia.github.io/nvidia-docker/ubuntu14.04/amd64/  Packages
 nvidia-docker2 | 2.0.3+docker17.03.2-1 | https://nvidia.github.io/nvidia-docker/ubuntu14.04/amd64/  Packages
```
### 安装nvidia-docker2
```bash
# 若docker-ce选择安装17.06.2~ce-0~ubuntu版本，则nvidia-container-runtime与nvidia-docker2都需要安装对应的版本，如下：
$ sudo apt-get install -y 17.06.2~ce-0~ubuntu
$ sudo apt-get install -y nvidia-docker2=2.0.3+docker17.06.2-1 nvidia-container-runtime=2.0.0+docker17.06.2-1
```
### 开启redis docker服务
```bash
$ docker pull redis
$ docker run -P --name verifier-redis redis
```
## GPU

### RESTFUL版本 (默认)
```bash
# current path is detector/docker/gpu
# build image
$ docker build -t verifier-restful:gpu -f Dockerfile .
# start container
# --link 参数绑定redis容器name
# 以下参数可以根据需求进行修改，通过nvidia-docker run指令选择性传入参数
# REDIS_HOST | REDIS_PORT | REDIS_PWD | CLASSIFY_THREADS | DETECT_THREADS | FEATURE_THREADS | SEARCH_THREADS
# 示例：
$ nvidia-docker run  -P -it  --rm --link verifier-redis:verifier-redis -e REDIS_HOST=verifier-redis  -e REDIS_PORT=6379 -e CLASSIFY_THREADS=2 verifier-restful:gpu
```
### ZMQ版本(取消Dockerfile与entrypoint.sh中ZMQ的注释，注释RESTFUL)
```bash
# current path is detector/docker/gpu
# build image
$ docker build -t verifier-zmq:gpu -f Dockerfile .
# start container
# --link 参数绑定redis容器name
# 以下参数可以根据需求进行修改，通过nvidia-docker run指令选择性传入参数
# REDIS_HOST(string) | REDIS_PORT(int) | REDIS_PWD(string) | CLASSIFY_THREADS(int) | DETECT_THREADS(int) | FEATURE_THREADS(int) | SEARCH_THREADS(int)
$ nvidia-docker run  -P -it  --rm --link verifier-redis:verifier-redis -e REDIS_HOST=verifier-redis  -e REDIS_PORT=6379 -e CLASSIFY_THREADS=2 verifier-zmq:gpu
```

## CPU

```bash
#current path is detector/docker
# build image
$ docker build -t verifier:cpu -f cpu/Dockerfile .
# start container
$ docker run -p 33388:33388 verifier:cpu
```
