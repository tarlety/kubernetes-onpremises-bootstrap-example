#!/bin/bash

HOSTFILE=${PWD}/VirtualBoxVMConfigs/hosts
USERNAME=`whoami`
NODE=master1

cat ${HOSTFILE} | ssh ${NODE} "sudo -n tee /etc/hosts"
ssh ${NODE} "
	sudo chown root /etc/hosts;
	sudo chgrp root /etc/hosts;
	sudo chmod 644 /etc/hosts;
	"

# install docker
ssh ${NODE} "
	sudo apt install docker.io -y ;
	sudo apt-mark hold docker.io ;
	sudo systemctl enable docker ;
	sudo usermod -a -G docker ${USERNAME} ;
	"

# docker log rotating
cat <<EOF | ssh ${NODE} "sudo -n tee /etc/docker/daemon.json"
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "10"
  }
}
EOF

