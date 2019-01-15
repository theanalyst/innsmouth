#!/bin/bash
set -x
. env.sh
cluster1=${1:-dc1}
cluster2=${2:-dc2}
PATH=$CEPH_DEV/build/bin/:$PATH
SCRIPT_PATH=$CEPH_DEV/src
pushd $CEPH_DEV/build

export ZONE_ACCESS_KEY=1555b35654ad1656d804
export ZONE_SECRET_KEY="h7GhxuBLTrlhVUyxSPUKUV8r/2EI4ngqJxD7iBdBYLhwluN30JaT3Q=="
export CEPH_CONF=./run/$cluster1/ceph.conf

if [ -z $ARGS ]
then
    echo "creating new cluster"
    ARGS="-n"
fi
echo "stopping existing services"
$SCRIPT_PATH/stop.sh
RGW=1 MDS=0 $SCRIPT_PATH/mstart.sh dc1 $ARGS
RGW=1 MDS=0 $SCRIPT_PATH/mstart.sh dc2 $ARGS
pkill radosgw
radosgw-admin realm create --rgw-realm=gold --default
radosgw-admin zonegroup create --rgw-zonegroup=us --endpoints=http://localhost:8001 --master --default
radosgw-admin zone create --rgw-zonegroup=us --rgw-zone=us-east-1 --access-key=$ZONE_ACCESS_KEY --secret=$ZONE_SECRET_KEY --endpoints=http://localhost:8001 --default --master

radosgw-admin user create --uid=zone.user --display-name="Zone User" --access-key=$ZONE_ACCESS_KEY --secret=$ZONE_SECRET_KEY --system

radosgw-admin period update --commit

$SCRIPT_PATH/mrgw.sh $cluster1 8001 --debug-rgw=1

echo "zone1 created"
sleep 30
export CEPH_CONF=run/$cluster2/ceph.conf
radosgw-admin realm pull --url=http://localhost:8001 --access-key=$ZONE_ACCESS_KEY --secret=$ZONE_SECRET_KEY
radosgw-admin realm default --rgw-realm=gold
radosgw-admin zone create --rgw-zonegroup=us --rgw-zone=us-west --access-key=$ZONE_ACCESS_KEY --secret=$ZONE_SECRET_KEY --endpoints=http://localhost:8002 --default
radosgw-admin period update --commit

$SCRIPT_PATH/mrgw.sh $cluster2 8002 --debug-rgw=1
popd
