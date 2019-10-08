#!/bin/bash

for t in master1,10.13.13.101,2201 worker1,10.13.13.102,2202 worker2,10.13.13.103,2203 worker3,10.13.13.104,2204 worker4,10.13.13.105,2205 master2,10.13.13.106,2206 master3,10.13.13.107,2207
do
	IFS=","
	set -- $t
	NODE=$1
	NODEIP=$2
	FORWARD_PORT=$3

	echo "Enable forwarding localhost:${FORWARD_PORT} to ${NODE}:22"
	VBoxManage controlvm ${NODE} natpf1 "ssh-${NODE},tcp,127.0.0.1,${FORWARD_PORT},,22"
	sudo iptables -t nat -A PREROUTING -p tcp \
		-d ${NODEIP} --dport 22 \
		-j DNAT --to-destination 127.0.0.1:${FORWARD_PORT}
	sudo iptables -t nat -A OUTPUT -p tcp \
		-d ${NODEIP} --dport 22 \
		-j DNAT --to-destination 127.0.0.1:${FORWARD_PORT}

	ssh-keygen -f ~/.ssh/known_hosts -R "${NODE}"
	ssh-keygen -f ~/.ssh/known_hosts -R "${NODEIP}"
	ssh-copy-id -o "StrictHostKeyChecking no" -i ~/.ssh/id_rsa "${NODE}"
done

for t in master1,10.13.13.101
do
	IFS=","
	set -- $t
	NODE=$1
	NODEIP=$2
	PORT=6443

	echo "Enable forwarding localhost:${PORT} to ${NODE}:${PORT}"
	VBoxManage controlvm ${NODE} natpf1 "${NODE}-${PORT},tcp,127.0.0.1,${PORT},,${PORT}"
	sudo iptables -t nat -A PREROUTING -p tcp \
		-d ${NODEIP} --dport ${PORT} \
		-j DNAT --to-destination 127.0.0.1:${PORT}
	sudo iptables -t nat -A OUTPUT -p tcp \
		-d ${NODEIP} --dport ${PORT} \
		-j DNAT --to-destination 127.0.0.1:${PORT}
done
