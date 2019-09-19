#!/bin/bash

for NODE in master1 worker1 worker2 worker3 worker4
do
	VBoxManage controlvm ${NODE} poweroff
	sleep 2
	VBoxManage unregistervm --delete ${NODE}
done

VBoxManage dhcpserver remove --netname intnet
