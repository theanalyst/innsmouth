#!/bin/bash

if [ -z $CEPH_DEV ]
then
    echo "please set CEPH_DEV to the directory containing ceph"
    exit 1
fi
