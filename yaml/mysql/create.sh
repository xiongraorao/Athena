#!/bin/bash

if [[ $# -lt 1 ]]
then
    echo "Usage: `basename $0` volume_name "
else
    ansible all -m shell -a  "mkdir -p /opt/gfs_data/$1"
    ansible all -m shell -a  "chmod 777 /opt/gfs_data/$1"
    gluster volume create $1 transport tcp cloud03:/opt/gfs_data/$1 cloud05:/opt/gfs_data/$1 cloud06:/opt/gfs_data/$1 force
    sleep 3
    gluster volume start $1
    # gluster 调优
    gluster volume quota $1 enable
    gluster volume quota $1 limit-usage / 100GB
    gluster volume set $1 performance.cache-size 4GB
    gluster volume set $1 performance.io-thread-count 16
    gluster volume set $1 network.ping-timeout 10
    gluster volume set $1 performance.write-behind-window-size 1024MB
fi
