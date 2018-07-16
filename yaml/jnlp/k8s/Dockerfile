FROM jenkins/jnlp-slave

MAINTAINER xiongraorao@gmail.com

LABEL Description="This is a extend image base from jenkins/jnlp-slave which install maven in it."

# 切换到 root 账户进行操作
USER root

# 安装 maven-3.3.9
#RUN wget http://mirrors.sonic.net/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz && \
RUN wget http://192.168.1.3/mirrors/maven/apache-maven-3.3.9-bin.tar.gz && \
    tar -zxf apache-maven-3.3.9-bin.tar.gz && \
    mv apache-maven-3.3.9 /usr/local && \
    rm -f apache-maven-3.3.9-bin.tar.gz && \
    ln -s /usr/local/apache-maven-3.3.9/bin/mvn /usr/bin/mvn && \
    ln -s /usr/local/apache-maven-3.3.9 /usr/local/apache-maven

# 安装 nodejs
#RUN wget https://nodejs.org/dist/v8.11.3/node-v8.11.3-linux-x64.tar.xz && \
RUN wget http://192.168.1.3/mirrors/nodejs/node-v8.11.3-linux-x64.tar.xz && \
    tar -xvf node-v8.11.3-linux-x64.tar.xz && \
    mv node-v8.11.3-linux-x64 /usr/local/nodejs && \
    ln -s /usr/local/nodejs/bin/node /usr/bin/node && \
    ln -s /usr/local/nodejs/lib/node_modules/npm/bin/npm-cli.js /usr/bin/npm && \
    rm -f node-v8.11.3-linux-x64.tar.xz

# 安装 kubernetes
COPY kubectl /usr/local/bin/kubectl

USER jenkins

# warning: if you mount /home/jenkins to a persistent volume, 'config' will disappear
COPY config /home/jenkins/.kube/config

# 安装docker client 和docker-compose

COPY docker /usr/local/bin/docker

COPY docker-compose /usr/local/bin/docker-compose

COPY libltdl.so.7.3.1 /usr/lib/x86_64-linux-gnu/libltdl.so.7
