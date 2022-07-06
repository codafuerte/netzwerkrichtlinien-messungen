#!/bin/bash



ROLE=$1
HOST_NAME=$2

# latenz

##s2s
s2s_latenz() {
    if [ -z "$1" ]; then
        echo "Make sure to set hostname, to which fortio-client should be deployed"
        exit 1
    fi

    if [ -z "$2" ]; then
        echo "Make sure to set hostname, to which fortio-server should be deployed"
        exit 1
    fi

    ./scripts/deploy-fortio.sh client gke-netzwerkrichtlinien--default-pool-65ce6097-qcsh

    ./scripts/deploy-fortio.sh server gke-netzwerkrichtlinien--default-pool-65ce6097-vrwb

} 

# througput

# skalierbarkeit

## Pod-Skalierbarkeit (Througput bei steigender Anzahl von Pods)

## Richtlinien-Skalierbarkeit (Througput bei steigender Anzahl von Richtlinien)