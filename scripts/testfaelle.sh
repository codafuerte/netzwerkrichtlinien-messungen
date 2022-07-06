#!/bin/bash

# latenz

##s2s
s2s_latenz() {

    FORTIO_CLIENT_HOST_NAME=$1
    FORTIO_SERVER_HOST_NAME=$2

    if [ -z "$FORTIO_CLIENT_HOST_NAME" ]; then
        echo "Make sure to set hostname, to which fortio-client should be deployed"
        exit 1
    fi

    if [ -z "$FORTIO_SERVER_HOST_NAME" ]; then
        echo "Make sure to set hostname, to which fortio-server should be deployed"
        exit 1
    fi

    ./scripts/deploy-fortio.sh client $FORTIO_CLIENT_HOST_NAME

    ./scripts/deploy-fortio.sh server $FORTIO_SERVER_HOST_NAME

    
} 

# througput

# skalierbarkeit

## Pod-Skalierbarkeit (Througput bei steigender Anzahl von Pods)

## Richtlinien-Skalierbarkeit (Througput bei steigender Anzahl von Richtlinien)