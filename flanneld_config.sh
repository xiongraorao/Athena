#!/bin/bash

if [[ $# -lt 1 ]]
then
    echo "Usage: `basename $0` etcd-cluster-memberIP"
  exit 1
fi

echo "===configure flanneld and restart docker daemon==="

etcdctl --endpoints=https://$1:2379 \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
  mkdir /kube-ubuntu/network

etcdctl --endpoints=https://$1:2379 \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
  mk /kube-ubuntu/network/config '{"Network":"172.30.0.0/16","SubnetLen":24,"Backend":{"Type":"vxlan"}}'

restart flanneld
if [ -f /run/flannel/docker ]
then
    line=$(cat /run/flannel/docker | wc -l)
    if [ $line==4 ]
    then
        echo ". /run/flannel/docker" > /etc/default/docker
        echo DOCKER_OPTS=\"\${DOCKER_NETWORK_OPTIONS}\" >> /etc/default/docker 
        service docker restart
        echo "restart docker successfully!"
    else
        echo "flannel service is not ready, please check file '/run/flannel/docker' "
    fi
fi
