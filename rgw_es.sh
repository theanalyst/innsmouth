#!/bin/bash
set -x
. env.sh
PATH=$CEPH_DEV/build/bin/:$PATH
pushd $CEPH_DEV/build
echo "creating realm..."
./bin/radosgw-admin realm create --rgw-realm=default
./bin/radosgw-admin zonegroup modify --rgw-zonegroup=default --rgw-realm=default
./bin/radosgw-admin zone modify --rgw-zonegroup=default --rgw-zone=default --access-key=zaccess --secret=zsecret
./bin/radosgw-admin zone modify --rgw-zonegroup=default --rgw-zone=default --endpoints=http://localhost:8000
./bin/radosgw-admin user create --uid=systemuser --access-key=zaccess --secret=zsecret --system --display-name=sysuser
pkill radosgw && ./bin/radosgw -n client.rgw --rgw-zone=default --log-file=out/rgw.log
./bin/radosgw-admin period update --commit


./bin/radosgw-admin zone create --rgw-zone=es --rgw-zonegroup=default --access-key=zaccess --secret=zsecret --endpoints=http://localhost:8001 --rgw-realm=default
./bin/radosgw-admin zone modify --rgw-zone=es --tier-type=elasticsearch --tier-config=endpoint=http://localhost:9200
./bin/radosgw-admin period update --commit
./bin/radosgw --rgw-zone=es --log-file=out/rgwes.log --rgw-frontends="civetweb port=8000"
popd