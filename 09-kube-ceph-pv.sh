#!/bin/bash

cat <<EOF | ssh master1 "kubectl create -f -"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: cephfs-pv-example
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 100Gi
  claimRef:
    namespace: default
    name: cephfs-pvc-example
  cephfs:
    monitors:
      - 10.13.13.101:6789
    path: /cephfs/example
    user: admin
    secretRef:
      name: ceph-secret
    readOnly: false
  persistentVolumeReclaimPolicy: Retain
EOF
