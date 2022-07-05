#!/bin/bash
if [ "$1" != "client" ] && [ "$1" != "server" ]; then
    echo "Make sure to set 'client' or 'server'"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Make sure to set hostname, to which fortio should be deployed"
fi

ROLE=$1
HOST_NAME=$2

deploy_fortio() {
    sudo sed -i "s/kubernetes.io\/hostname:/kubernetes.io\/hostname: $HOST_NAME/" kubernetes/fortio.$ROLE.deployment.yaml
    kubectl apply -f kubernetes/fortio.$ROLE.deployment.yaml 
}

deploy_fortio