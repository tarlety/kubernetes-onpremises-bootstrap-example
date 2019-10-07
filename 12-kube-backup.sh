#!/bin/bash

ETCDIMAGE=k8s.gcr.io/etcd:3.3.10

ssh master1 "docker run --rm \
	-v \$(pwd):/backup \
	--network host \
	-v /etc/kubernetes/pki/etcd:/etc/kubernetes/pki/etcd \
	--env ETCDCTL_API=3 \
	${ETCDIMAGE} \
	etcdctl \
	--endpoints=https://127.0.0.1:2379 \
	--cacert=/etc/kubernetes/pki/etcd/ca.crt \
	--cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
	--key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
	snapshot save /backup/etcd-snapshot-latest.db"

ssh master1 "sudo tar -zcpf - -C /etc/kubernetes/pki ." | cat > kubepki.tgz
ssh master1 "tar -zcf - etcd-snapshot-latest.db" | cat > etcd-snapshot-latest.tgz

ssh master1 "rm etcd-snapshot-latest.db"
