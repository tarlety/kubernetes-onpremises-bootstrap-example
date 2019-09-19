#!/bin/bash

echo "Enable forwarding localhost:2201 to ${NODE}:22"
VBoxManage controlvm ${NODE} natpf1 "ssh-${NODE},tcp,127.0.0.1,2201,22"
sudo iptables -t nat -A PREROUTING -p tcp \
	-d 10.13.13.101 --dport 22 \
	-j DNAT --to-destination 127.0.0.1:2201 \
sudo iptables -t nat -A OUTPUT -p tcp \
	-d 10.13.13.101 --dport 22 \
	-j DNAT --to-destination 127.0.0.1:2201 \

