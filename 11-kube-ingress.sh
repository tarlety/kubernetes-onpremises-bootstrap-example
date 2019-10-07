#!/bin/bash

SUBJECT=/C=CN/ST=State/L=Location/O=Org/OU=Unit/CN=example.com

openssl genrsa -out cert.key
openssl req -sha512 -new -key cert.key -out cert.req -subj "${SUBJECT}"
openssl x509 -sha512 -req -days 730 -in cert.req -signkey cert.key -out cert.crt -extfile v3.ext

cat cert.key | ssh master1 "kubectl create secret generic traefik-cert-key --from-file=cert.key=/dev/stdin -n kube-system"
cat cert.crt | ssh master1 "kubectl create secret generic traefik-cert-crt --from-file=cert.crt=/dev/stdin -n kube-system"

cat traefik.toml | ssh master1 "kubectl create configmap traefik-conf -n kube-system --from-file=traefik.toml=/dev/stdin"
cat traefik-rbac.yaml | ssh master1 "kubectl create -f -"
cat traefik-ds.yaml | ssh master1 "kubectl create -f -"
