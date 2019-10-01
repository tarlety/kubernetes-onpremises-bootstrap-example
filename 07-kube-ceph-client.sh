#!/bin/bash

CEPHCOMMON_VERSION='=12.2.12-0ubuntu0.18.04.3'
ACTIVEMDS='master1'

for NODE in master1 worker1 # worker2
do
	ssh ${NODE} "
		sudo apt install ceph-common${CEPHCOMMON_VERSION} autofs -y ;
		sudo apt-mark hold ceph-common ;
		echo \$(sudo grep key /etc/ceph/ceph.client.admin.keyring  | cut -d= -f2-) | \
			sudo tee /etc/ceph/admin.secret ;
		sudo chmod 600 /etc/ceph/admin.secret ;
		cat /etc/auto.misc | grep '^mds' | grep ceph | grep ${ACTIVEMDS} || \
			echo 'mds -fstype=ceph,noatime,nodiratime,name=admin,secretfile=/etc/ceph/admin.secret ${ACTIVEMDS}:/' | \
			sudo tee -a /etc/auto.misc ;
		cat /etc/auto.master | grep mnt | grep -F '/etc/auto.misc' || \
			echo '/mnt/misc /etc/auto.misc --timeout 0' | \
			sudo tee -a /etc/auto.master ;
		sudo service autofs restart ;
		"
done
