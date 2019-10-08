#!/bin/bash

KUBERNETES_VERSION='=1.16.1-00'
NETWORK=10.244.0.0/16
VIP=10.13.13.201
DEV=enp0s8

for t in master1,10.13.13.101
do
	IFS=","
	set -- $t
	NODE=$1
	NODEIP=$2

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

	ssh ${NODE} "sudo ip addr add ${VIP}/24 dev ${DEV}"

	ssh ${NODE} "
		sudo kubeadm init \
			--pod-network-cidr ${NETWORK} \
			--apiserver-advertise-address ${NODEIP} \
			--control-plane-endpoint '${VIP}:6443' \
			--upload-certs \
			--v=5" 2>&1 > init

	ssh ${NODE} "
		mkdir -p \${HOME}/.kube ;
		sudo cp -f /etc/kubernetes/admin.conf \${HOME}/.kube/config ;
		sudo chown \$(id -u):\$(id -g) \${HOME}/.kube/config ;
		"

	ssh ${NODE} "kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/canal.yaml"
done

