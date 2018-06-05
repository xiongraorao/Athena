#!/bin/bash
helm server &
helm repo add local http://localhost:8879/charts
git clone https://github.com/ceph/ceph-helm
cd ceph-helm/ceph
make

touch ./ceph-overrides.yaml
cat > ./ceph-overrides.yaml << EOF
network:
  public:   172.21.0.0/20
  cluster:   172.21.0.0/20

osd_devices:
  - name: dev-sdd
    device: /dev/sdd
    zap: "1"
  - name: dev-sde
    device: /dev/sde
    zap: "1"

storageclass:
  name: ceph-rbd
  pool: rbd
  user_id: k8s
EOF

kubectl create namespace ceph
kubectl create -f ./ceph-helm/ceph/rbac.yaml
kubectl label node 192.168.1.5 ceph-mon=enabled ceph-mgr=enabled
for ip in 3 5 6;
do kubectl label node 192.168.1.$ip ceph-osd=enabled ceph-osd-device-dev-sdd=enabled ceph-osd-device-dev-sde=enabled --overrides;
done;

