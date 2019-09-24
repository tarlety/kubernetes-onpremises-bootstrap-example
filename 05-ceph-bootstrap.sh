#!/bin/bash

DOCKERIMAGE=ceph/daemon:v3.2.1-stable-3.2-luminous-debian-9-x86_64
NETWORK=10.13.13.0/24

MON1=master1
MON1IP=10.13.13.101

MON2=worker1
MON2IP=10.13.13.102

MON3=worker2
MON3IP=10.13.13.103

MONS=${MON1},${MON2},${MON3}
MONSIP=${MON1IP},${MON2IP},${MON3IP}

PGNUM=64

# Bootstrap Ceph by MON1

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
	sudo mkdir -p ~/pack/ceph/etc ~/pack/ceph/var/lib/ceph ;
	sudo cp -rf /etc/ceph ~/pack/ceph/etc/ ;
	sudo cp -rf /var/lib/ceph/bootstrap-mds ~/pack/ceph/var/lib/ceph ;
	sudo cp -rf /var/lib/ceph/bootstrap-osd ~/pack/ceph/var/lib/ceph ;
	sudo cp -rf /var/lib/ceph/bootstrap-rbd ~/pack/ceph/var/lib/ceph ;
	sudo cp -rf /var/lib/ceph/bootstrap-rgw ~/pack/ceph/var/lib/ceph ;
	sudo chown -R 64045:64045 ~/pack/ceph/var/lib/ceph ;
	"

for MON in ${MON2} ${MON3}
do
	ssh ${MON} "sudo mkdir -p ~/pack/ceph"

	ssh ${MON1} "sudo tar -zcpf - -C ~/pack/ceph ." | ssh ${MON} "sudo tar zxpf - -C ~/pack/ceph"

	ssh ${MON} "
		sudo cp -rf ~/pack/ceph/etc/ceph /etc ;
		sudo cp -rf ~/pack/ceph/var/lib/ceph /var/lib ;
		sudo mkdir -p /var/log/ceph ;
		sudo chmod go-rwx /var/log/ceph /var/lib/ceph ;
		sudo chown 64045:64045 /var/log/ceph /var/lib/ceph ;
		sudo rm -rf ~/pack ;
		"
done

ssh ${MON1} "sudo rm -rf ~/pack"

for t in ${MON1},${MON1IP} ${MON2},${MON2IP} ${MON3},${MON3IP}
do
	IFS=","
	set -- $t
	MON=$1
	MONIP=$2

	ssh ${MON} "
		docker run -d --net=host \
			--restart=always \
			-v /etc/ceph:/etc/ceph \
			-v /var/log/ceph/:/var/log/ceph/ \
			-v /var/lib/ceph/mon:/var/lib/ceph/mon \
			-v /var/lib/ceph/bootstrap-mds:/var/lib/ceph/bootstrap-mds \
			-v /var/lib/ceph/bootstrap-osd:/var/lib/ceph/bootstrap-osd \
			-v /var/lib/ceph/bootstrap-rbd:/var/lib/ceph/bootstrap-rbd \
			-v /var/lib/ceph/bootstrap-rgw:/var/lib/ceph/bootstrap-rgw \
			-e MON_IP=${MONIP} \
			-e CEPH_PUBLIC_NETWORK=$NETWORK \
			--name mon \
			${DOCKERIMAGE} mon
		"
done

# Bootstrap mgr/osd/mds daemon

for NODE in ${MON1} ${MON2} ${MON3}
do
	ssh ${NODE} "
		docker run -d --net=host \
			--restart=always \
			-v /etc/ceph:/etc/ceph \
			-v /var/log/ceph/:/var/log/ceph/ \
			-v /var/lib/ceph/mgr:/var/lib/ceph/mgr \
			-v /var/lib/ceph/bootstrap-mds:/var/lib/ceph/bootstrap-mds \
			-v /var/lib/ceph/bootstrap-osd:/var/lib/ceph/bootstrap-osd \
			-v /var/lib/ceph/bootstrap-rbd:/var/lib/ceph/bootstrap-rbd \
			-v /var/lib/ceph/bootstrap-rgw:/var/lib/ceph/bootstrap-rgw \
			--name mgr \
			${DOCKERIMAGE} mgr
		"

	for DEV in /dev/sdb /dev/sdc
	do
		OSDNAME=osd${DEV//\//-}
		ssh ${NODE} "
			docker run --rm --privileged=true \
				-v /dev/:/dev/ \
				-e OSD_DEVICE=$DEV \
				${DOCKERIMAGE} zap_device
			"
		ssh ${NODE} "
			docker run -d --net=host \
			    --pid=host \
			    --restart=always \
			    --privileged=true \
			    -v /etc/ceph:/etc/ceph \
			    -v /var/log/ceph/:/var/log/ceph/ \
			    -v /var/lib/ceph/bootstrap-mds:/var/lib/ceph/bootstrap-mds \
			    -v /var/lib/ceph/bootstrap-osd:/var/lib/ceph/bootstrap-osd \
			    -v /var/lib/ceph/bootstrap-rbd:/var/lib/ceph/bootstrap-rbd \
			    -v /var/lib/ceph/bootstrap-rgw:/var/lib/ceph/bootstrap-rgw \
			    -v /dev/:/dev/ \
			    -e OSD_DEVICE=$DEV \
			    --name $OSDNAME \
			    ${DOCKERIMAGE} osd
			"
	done

	ssh ${NODE} "
		docker run -d --net=host \
			--restart=always \
			-v /etc/ceph:/etc/ceph \
			-v /var/log/ceph/:/var/log/ceph/ \
			-v /var/lib/ceph/mds:/var/lib/ceph/mds \
			-v /var/lib/ceph/bootstrap-mds:/var/lib/ceph/bootstrap-mds \
			-v /var/lib/ceph/bootstrap-osd:/var/lib/ceph/bootstrap-osd \
			-v /var/lib/ceph/bootstrap-rbd:/var/lib/ceph/bootstrap-rbd \
			-v /var/lib/ceph/bootstrap-rgw:/var/lib/ceph/bootstrap-rgw \
			-e CEPHFS_CREATE=1 \
			-e CEPHFS_DATA_POOL_PG=$PGNUM \
			-e CEPHFS_METADATA_POOL_PG=$PGNUM \
			--name mds \
			${DOCKERIMAGE} mds
		"
done
