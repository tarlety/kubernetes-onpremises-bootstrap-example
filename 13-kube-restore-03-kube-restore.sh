#!/bin/bash

ETCDIMAGE=k8s.gcr.io/etcd:3.3.10

ssh master1 "sudo mkdir -p /etc/kubernetes/pki"
cat kubepki.tgz | ssh master1 "sudo tar zxpf - -C /etc/kubernetes/pki"

cat etcd-snapshot-latest.tgz | ssh master1 "tar zxf -"
ssh master1 "
	sudo mkdir -p /var/lib/etcd ;
	docker run --rm \
		-v \$(pwd):/backup \
		-v '/var/lib/etcd:/var/lib/etcd' \
		--env ETCDCTL_API=3 \
		${ETCDIMAGE} \
		/bin/sh -c 'etcdctl \
			--endpoints=https://127.0.0.1:2379 \
			--cacert=/etc/kubernetes/pki/etcd/ca.crt \
			--cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
			--key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
			snapshot restore '/backup/etcd-snapshot-latest.db' ; mv /default.etcd/member/ /var/lib/etcd/'"

ssh master1 "rm etcd-snapshot-latest.db"
