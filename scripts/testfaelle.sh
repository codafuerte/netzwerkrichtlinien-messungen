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

    # Fortio Client mit 1 Replika deployen 
    ./scripts/manage-fortio.sh deploy-fortio --role=client --host-name=${FORTIO_CLIENT_HOST_NAME}

    # Fortio Server mit 1 Replika deployen 
    ./scripts/manage-fortio.sh deploy-fortio --role=server --host-name=${FORTIO_SERVER_HOST_NAME}

    TECHNOLOGIES=('cilium' 'istio')
    REPETITIONS=$(seq 2)

    for technology in "${TECHNOLOGIEN[@]}"
    do
        # Netzwerkrichtlinie erstellen, die s2s Verkehr zulässt
        ./scripts/deploy-policies.sh create-and-deploy-policies $technology 1
        
        for i in "${REPETITIONS[@]}"
        do
            # Messung der s2s-Latenz bei minimaler Auslastung. Pro CPU 1 Thread und 1 Anfrage pro Sekunde
            ./scripts/run-fortio-load.sh --qps=4 --num-calls=100 --server-address=fortio-server-service --port=8080 --output=s2s_latenz_${technology}_durchgang_${i} --content-type=application/json
        done
        # Netzwerkrichtlinie löschen, die s2s Verkehr zulässt
        ./scripts/deploy-policies.sh delete-policies $technology 1
    done

    # Fortio Client löschen 
    ./scripts/manage-fortio.sh deploy-fortio --role=client --host-name=${FORTIO_CLIENT_HOST_NAME}

    # Fortio Server löschen
    ./scripts/manage-fortio.sh deploy-fortio --role=server --host-name=${FORTIO_SERVER_HOST_NAME}
} 

s2s_latenz

# througput

# skalierbarkeit

## Pod-Skalierbarkeit (Througput bei steigender Anzahl von Pods)

## Richtlinien-Skalierbarkeit (Througput bei steigender Anzahl von Richtlinien)