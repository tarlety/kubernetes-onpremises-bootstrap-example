#!/bin/bash

cat <<EOF | ssh master1 "kubectl create -f -"
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: cephfs-pvc-example
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
---
kind: Pod
apiVersion: v1
metadata:
  name: pod-example
spec:
  containers:
  - name: ubuntu
    image: ubuntu
    volumeMounts:
    - mountPath: /data
      name: data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: cephfs-pvc-example
EOF
