#!/bin/bash

RAMSIZE=${1:-2048}

VBoxManage dhcpserver add --netname intnet \
  --ip 10.13.13.100 \
  --netmask 255.255.255.0 \
  --lowerip 10.13.13.101 --upperip 10.13.13.254 \
  --enable

for NODE in master1 master2 master3 # worker1 worker2 # worker3 worker4
do
	VBoxManage createvm --name ${NODE} --register
	VBoxManage modifyvm ${NODE} \
		--cpus 2 \
		--memory ${RAMSIZE} \
		--acpi on \
		--boot2 dvd \
		--nic1 nat --nic2 intnet \
		--ioapic on \
		--ostype Ubuntu_64
	VBoxManage storagectl ${NODE} --name "SATA Controller" --add sata
	VBoxManage storagectl ${NODE} --name "IDE Controller" --add ide

	for id in 1 2
	do
	    DISK="${HOME}/VirtualBox VMs/${NODE}/disk-${id}.vdi"
	    VBoxManage createvdi --filename "${DISK}" --size 10240
	    VBoxManage storageattach ${NODE} \
		    --storagectl "SATA Controller" --port ${id} --device 0 \
		    --type hdd --medium "${DISK}"
	done
done
