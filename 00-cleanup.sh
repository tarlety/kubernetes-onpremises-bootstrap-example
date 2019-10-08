#!/bin/bash

for t in master1,10.13.13.101 worker1,10.13.13.102 worker2,10.13.13.103 worker3,10.13.13.104 worker4,10.13.13.105 master2,10.13.13.106 master3,10.13.13.107
do
	IFS=","
	set -- $t
	NODE=$1
	NODEIP=$2

	VBoxManage controlvm ${NODE} poweroff
	sleep 2
	VBoxManage unregistervm --delete ${NODE}

	ssh-keygen -f ~/.ssh/known_hosts -R "${NODE}"
	ssh-keygen -f ~/.ssh/known_hosts -R "${NODEIP}"
done

VBoxManage dhcpserver remove --netname intnet

for t in master1,10.13.13.101,2201 worker1,10.13.13.102,2202 worker2,10.13.13.103,2203 worker3,10.13.13.104,2204 worker4,10.13.13.105,2205 master2,10.13.13.106,2206 master3,10.13.13.207,2207
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

