#!/bin/bash

KUBERNETES_VERSION='=1.16.1-00'
NETWORK=10.244.0.0/16
VIP=10.13.13.201
MASTERIP=10.13.13.101
DEV=enp0s8

TOKEN=$(cat init | grep 'kubeadm join' | head -1 | rev | cut -d' ' -f2 | rev)
HASH=$(cat init | grep 'discovery-token-ca-cert-hash' | head -1 | rev | cut -d' ' -f2 | rev)
KEY=$(cat init | grep 'certificate-key' | head -1 | rev | cut -d' ' -f1 | rev)

for t in master2,10.13.13.106 master3,10.13.13.107
do
	IFS=","
	set -- $t
	NODE=$1
	NODEIP=$2

	ssh ${NODE} "sudo ip addr add ${NODEIP}/24 dev ${DEV}"

	ssh ${NODE} "
		sudo apt update -y;
		sudo apt install -y apt-transport-https curl gpg;
		curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - ;
		echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list ;
		sudo apt update -y ;
		sudo apt install -y kubelet${KUBERNETES_VERSION} kubeadm${KUBERNETES_VERSION} kubectl${KUBERNETES_VERSION} ;
		sudo apt-mark hold kubelet kubeadm kubectl ;
		sudo swapoff -a ;
		sudo sed -i -e 's/^\\([^#].*swap.*\\)$/#\\1/g' /etc/fstab ;
		"

	ssh ${NODE} "
		sudo kubeadm join ${VIP}:6443 \
			--token ${TOKEN} \
			--discovery-token-ca-cert-hash ${HASH} \
			--control-plane --certificate-key ${KEY} \
			--apiserver-advertise-address ${NODEIP} \
			--v=5"
done

