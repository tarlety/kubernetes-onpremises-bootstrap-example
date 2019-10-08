#!/bin/bash

#KUBERNETES_VERSION='=1.15.0-00'
NETWORK=10.244.0.0/16
VIP=10.13.13.201

TOKEN=$(cat init | grep 'kubeadm join' | head -1 | rev | cut -d' ' -f2 | rev)
HASH=$(cat init | grep 'discovery-token-ca-cert-hash' | head -1 | rev | cut -d' ' -f2 | rev)
KEY=$(cat init | grep 'certificate-key' | head -1 | rev | cut -d' ' -f1 | rev)

for NODEIP in 10.13.13.102 10.13.13.103
do
    ssh ${NODEIP} "
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

    ssh ${NODEIP} "sudo kubeadm join ${VIP}:6443 --token ${TOKEN} --discovery-token-ca-cert-hash ${HASH} --control-plane --certificate-key ${KEY} --apiserver-advertise-address ${NODEIP} --v=5"
done

