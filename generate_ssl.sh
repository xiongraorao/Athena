#!/bin/bash

if [[ $# -lt 1 ]]
then
    echo "Usage: `basename $0` workNode1 workNode2 workNode3 ..."
  exit 1
fi

args=($@)
length=${#args[@]}
let length--;
CSR_IP=""
for i in `seq 0 $length `
do
    CSR_IP=${CSR_IP}\"${args[i]}\",
done

TMP_DIR=./tmp
mkdir -p ${TMP_DIR}
cd ${TMP_DIR}

# 1. 创建CA配置文件
cfssl print-defaults config > config.json
cfssl print-defaults csr > csr.json
# 根据config.json文件的格式创建如下的ca-config.json文件
# 过期时间设置成了 87600h
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF

# 2.创建CA证书签名请求
cat > ca-csr.json << EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ],
    "ca": {
       "expiry": "87600h"
    }
}
EOF

# 3. 生成 CA 证书和私钥
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
# ls ca*
# ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem

# 4. 创建kubernetes证书签名请求文件
# 注意将hosts字段的ip地址替换成实际的集群node的ip地址
cat > kubernetes-csr.json << EOF
{
    "CN": "kubernetes",
    "hosts": [
      "127.0.0.1",
	  ${CSR_IP}
      "10.254.0.1",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "BeiJing",
            "L": "BeiJing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF

# 5. 生成kubernetes 证书和私钥
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes
#ls kubernetes*
# kubernetes.csr  kubernetes-csr.json  kubernetes-key.pem  kubernetes.pem

# 6. 创建admin证书签名请求文件
cat > admin-csr.json << EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "system:masters",
      "OU": "System"
    }
  ]
}
EOF

# 7. 生成admin证书签名请求文件
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin

#ls admin*
# admin.csr  admin-csr.json  admin-key.pem  admin.pem

# 8. 创建kube-proxy证书签名请求文件
cat > kube-proxy-csr.json << EOF
{
  "CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

# 9. 生成kube-proxy签名请求文件
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy
#ls kube-proxy*
# kube-proxy.csr  kube-proxy-csr.json  kube-proxy-key.pem  kube-proxy.pem

# 10. 分发证书
mkdir pem
cp ./*.pem pem/
for i in `seq 0 $length`
do
	scp  -o StrictHostKeyChecking=no pem/* root@${args[i]}:/etc/kubernetes/ssl/
done

# 11. clean
rm -rf ../tmp
