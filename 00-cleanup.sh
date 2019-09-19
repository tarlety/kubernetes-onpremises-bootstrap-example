#!/bin/bash

for NODE in master1 worker1 worker2 worker3 worker4
do
	VBoxManage controlvm ${NODE} poweroff
	sleep 2
	VBoxManage unregistervm --delete ${NODE}
done

VBoxManage dhcpserver remove --netname intnet

for t in master1,10.13.13.101,2201 worker1,10.13.13.102,2202 worker2,10.13.13.103,2203 worker3,10.13.13.104,2204 worker4,10.13.13.105,2205
do
	IFS=","
	set -- $t
	NODE=$1
	NODEIP=$2
	FORWARD_PORT=$3

	echo "Disable forwarding localhost:${FORWARD_PORT} to ${NODE}:22"
	VBoxManage controlvm ${NODE} natpf1 delete "ssh-${NODE}"
	sudo iptables -t nat -D PREROUTING -p tcp \
		-d ${NODEIP} --dport 22 \
		-j DNAT --to-destination 127.0.0.1:${FORWARD_PORT}
	sudo iptables -t nat -D OUTPUT -p tcp \
		-d ${NODEIP} --dport 22 \
		-j DNAT --to-destination 127.0.0.1:${FORWARD_PORT}
done
