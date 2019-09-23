#!/bin/bash

ISO=~/Documents/iso/ubuntu-18.04.2-server-amd64.iso
USERNAME=`whoami`
PASSWORD=iamironman

for NODE in master1 worker1 worker2 # worker3 worker4
do
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
done

