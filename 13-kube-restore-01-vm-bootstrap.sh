#!/bin/bash

RAMSIZE=${1:-2048}

NODE=master1
ssh-keygen -f ~/.ssh/known_hosts -R "${NODE}"
ssh-keygen -f ~/.ssh/known_hosts -R "${NODEIP}"

VBoxManage controlvm ${NODE} poweroff
sleep 2
VBoxManage unregistervm --delete ${NODE}

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

ISO=~/Documents/iso/ubuntu-18.04.2-server-amd64.iso
USERNAME=`whoami`
PASSWORD=iamironman

VBoxManage storageattach ${NODE} \
	--storagectl "IDE Controller" --port 0 --device 0 \
	--type dvddrive --medium ${ISO}

# unattended installation https://www.debian.org/releases/etch/ia64/apbs04.html.zh_CN
VBoxManage unattended install \
	${NODE} \
	--iso=${ISO} \
	--hostname=${NODE}.localhost \
	--user=${USERNAME} --password=${PASSWORD} \
	--locale=en_US --country=TW --time-zone=UTC \
	--script-template=${PWD}/ubuntu-preseed.cfg \
	--post-install-template=${PWD}/ubuntu-postinstall.sh \
	--start-vm=headless

