#!/bin/bash

DOCKERIMAGE=ceph/daemon:v3.2.1-stable-3.2-luminous-debian-9-x86_64
NETWORK=10.13.13.0/24

MONS=master1,worker1,worker2
MONSIP=10.13.13.101,10.13.13.102,10.13.13.103

MON1=master1
MON1IP=10.13.13.101

ssh ${MON1} "
	docker run -d --net=host \
		--restart=always \
		-v /etc/ceph:/etc/ceph \
		-v /var/log/ceph/:/var/log/ceph/ \
		-v /var/lib/ceph/mon:/var/lib/ceph/mon \
		-v /var/lib/ceph/bootstrap-mds:/var/lib/ceph/bootstrap-mds \
		-v /var/lib/ceph/bootstrap-osd:/var/lib/ceph/bootstrap-osd \
		-v /var/lib/ceph/bootstrap-rbd:/var/lib/ceph/bootstrap-rbd \
		-v /var/lib/ceph/bootstrap-rgw:/var/lib/ceph/bootstrap-rgw \
		-e MON_IP=${MON1IP} \
		-e CEPH_PUBLIC_NETWORK=$NETWORK \
		--name mon \
		${DOCKERIMAGE} mon
	"

for ROLE in osd mds rbd rgw
do
	while ssh ${MON1} "sudo [ ! -f /var/lib/ceph/bootstrap-${ROLE}/ceph.keyring ]"
	do
		echo Waiting bootstrap-${ROLE}/ceph.keyring...
		sleep 1
	done
done


ssh ${MON1} "
	sudo sed -i -e 's/^mon initial members = .*/mon initial members = ${MONS}/' /etc/ceph/ceph.conf ;
	sudo sed -i -e 's/^mon host = .*/mon host = ${MONSIP}/' /etc/ceph/ceph.conf ;
	"

ssh ${MON1} "
	docker stop mon ; docker rm mon ;
	sudo rm -rf /var/lib/ceph/mon ;
	sudo mkdir -p ~//ceph/etc ~//ceph/var/lib/ceph ;
	sudo cp -rf /etc/ceph ~/store/ceph/etc/ ;
	sudo cp -rf /var/lib/ceph/bootstrap-mds ~/store/ceph/var/lib/ceph ;
	sudo cp -rf /var/lib/ceph/bootstrap-osd ~/store/ceph/var/lib/ceph ;
	sudo cp -rf /var/lib/ceph/bootstrap-rbd ~/store/ceph/var/lib/ceph ;
	sudo cp -rf /var/lib/ceph/bootstrap-rgw ~/store/ceph/var/lib/ceph ;
	sudo chown -R 64045:64045 ~/store/ceph/var/lib/ceph ;
	"

