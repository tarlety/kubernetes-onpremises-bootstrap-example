#!/bin/bash

cat <<EOF | ssh master1 "bash -s"
KEY=\$(sudo cat /etc/ceph/ceph.client.admin.keyring | grep key | cut -d= -f2-)
cat <<EOFEOF | kubectl create -f -
apiVersion: v1
data:
  key: \$(echo \${KEY} | base64)
kind: Secret
metadata:
  name: ceph-secret
  namespace: default
type: Opaque
EOFEOF
EOF

