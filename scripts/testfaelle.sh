#!/bin/bash

s2s_test_bed() {

    TEST_CASE=$1
    FORTIO_SCRIPT=$2
    TECHNOLOGY=$3
    REPETITIONS=$4
    NUM_PODS=$5
    NUM_POLICIES=$6
    FORTIO_CLIENT_HOST_NAME=$7
    FORTIO_SERVER_HOST_NAME=$8

    echo "TEST_CASE $TEST_CASE"
    echo "FORTIO_SCRIPT $FORTIO_SCRIPT"
    echo "TECHNOLOGY $TECHNOLOGY"
    echo "REPETITIONS $REPETITIONS"
    echo "NUM_PODS $NUM_PODS"
    echo "NUM_POLICIES $NUM_POLICIES"
    echo "FORTIO_CLIENT_HOST_NAME $FORTIO_CLIENT_HOST_NAME"
    echo "FORTIO_SERVER_HOST_NAME $FORTIO_SERVER_HOST_NAME"

    if [ -z "$TEST_CASE" ]; then
        echo "Make sure to set the name of the testcase (e.g. latenz, durchsatz, pod_skalierbarkeit, richtlinien_skalierbarkeit)"
        exit 1
    fi

    if [ -z "$FORTIO_SCRIPT" ]; then
        echo "Make sure to set the fortio script for the load test"
        exit 1
    fi
    
    if [ "$TECHNOLOGY" != "cilium" ] && [ "$TECHNOLOGY" != "istio" ] && [ "$TECHNOLOGY" != "base" ]; then
        echo "Make sure to set technology under test (cilium, istio, base)"
        exit 1
    fi

    if [ -z "$REPETITIONS" ]; then
        echo "Make sure to set the number of repetitions"
        exit 1
    fi

    if [ -z "$NUM_PODS" ]; then
        echo "Make sure to set the number of pods, to which fortio-server should be deployed"
        exit 1
    fi

    if [ -z "$NUM_POLICIES" ]; then
        echo "Make sure to set the number of applied policies"
        exit 1
    fi

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

    # Warten bis Pods Ready sind
    kubectl wait --for=condition=ready pods --all --timeout=60s

    REPETITIONS=($(seq 1 ${REPETITIONS}))
    
    for i in "${REPETITIONS[@]}"
    do
        for pod in "${NUM_PODS[@]}"
        do

             # Fortio Server skalieren
            ./scripts/manage-fortio.sh scale-fortio --num-pods=${pod} --role=server
            # Warten bis Pods Ready sind
            kubectl wait --for=condition=ready pods --all --timeout=60s

            for policy in "${NUM_POLICIES[@]}"
            do
                # Netzwerkrichtlinien erstellen
                ./scripts/deploy-policies.sh create-and-deploy-policies $TECHNOLOGY $policy

                OUTPUT=--output=s2s_${TEST_CASE}_${TECHNOLOGY}_pods_${pod}_richtlinien_${policy}_durchgang_${i}
                FORTIO_SCRIPT="${2} ${OUTPUT}"

                # Messung durchführen
                $( $FORTIO_SCRIPT )

                 # Netzwerkrichtlinien löschen
                ./scripts/deploy-policies.sh delete-policies $TECHNOLOGY $policy
            done
        done
    done

    # Fortio Client löschen 
    ./scripts/manage-fortio.sh remove-fortio --role=client
    # Fortio Server löschen
    ./scripts/manage-fortio.sh remove-fortio --role=server
} 

## Latenz
# Messung der s2s-Latenz bei minimaler Auslastung. Pro CPU 1 Thread und 1 Anfrage pro Sekunde
latenz() {
    NUM_PODS=( 1 )
    NUM_POLICIES=( 1 )
    FORTIO_SCRIPT='./scripts/run-fortio-load.sh --qps=4 --connections=4 --num-calls=100 --server-address=fortio-server-service --port=8080 --content-type=application/json' 
    TECHNOLOGY=$1
    NUM_REPITIONS=$2
    FORTIO_CLIENT_HOST_NAME=$3
    FORTIO_SERVER_HOST_NAME=$4

    s2s_test_bed latenz "$FORTIO_SCRIPT" "$TECHNOLOGY" "$NUM_REPITIONS" "$NUM_PODS" "$NUM_POLICIES" "$FORTIO_CLIENT_HOST_NAME" "$FORTIO_SERVER_HOST_NAME"
}

## Durchsatz
# Messung des maximalen s2s-Durchsatz bei 32 Threads
durchsatz() {
    NUM_PODS=( 1 )
    NUM_POLICIES=( 1 )
    FORTIO_SCRIPT='./scripts/run-fortio-load.sh --qps=0 --connections=32 --duration=30s --server-address=fortio-server-service --port=8080 --content-type=application/json'
    TECHNOLOGY=$1
    NUM_REPITIONS=$2
    FORTIO_CLIENT_HOST_NAME=$3
    FORTIO_SERVER_HOST_NAME=$4

    s2s_test_bed durchsatz "$FORTIO_SCRIPT" "$TECHNOLOGY" "$NUM_REPITIONS" "$NUM_PODS" "$NUM_POLICIES" "$FORTIO_CLIENT_HOST_NAME" "$FORTIO_SERVER_HOST_NAME"
}


# Richtlinien-Skalierbarkeit
# Durchsatz bei steigender Anzahl von Pods
richtlinien_skalierbarkeit() {
    NUM_PODS=( 1 )
    NUM_POLICIES=( 1 2 4 8 16 32 64 128 256 512 )
    FORTIO_SCRIPT='./scripts/run-fortio-load.sh --qps=0 --connections=32 --duration=30s --server-address=fortio-server-service --port=8080 --content-type=application/json'
    TECHNOLOGY=$1
    NUM_REPITIONS=$2
    FORTIO_CLIENT_HOST_NAME=$3
    FORTIO_SERVER_HOST_NAME=$4

    s2s_test_bed richtlinien_skalierbarkeit "$FORTIO_SCRIPT" "$TECHNOLOGY" "$NUM_REPITIONS" "$NUM_PODS" "$NUM_POLICIES" "$FORTIO_CLIENT_HOST_NAME" "$FORTIO_SERVER_HOST_NAME"
}


# Pod-Skalierbarkeit
# Durchsatz bei steigender Anzahl von Pods
pod_skalierbarkeit() {
    NUM_PODS=( 1 5 10 15 20 25 30 35 50 45 50 55 60 )
    NUM_POLICIES=( 1 )
    FORTIO_SCRIPT='./scripts/run-fortio-load.sh --qps=0 --connections=32 --duration=30s --server-address=fortio-server-service --port=8080 --content-type=application/json'
    TECHNOLOGY=$1
    NUM_REPITIONS=$2
    FORTIO_CLIENT_HOST_NAME=$3
    FORTIO_SERVER_HOST_NAME=$4

    s2s_test_bed pod_skalierbarkeit "$FORTIO_SCRIPT" "$TECHNOLOGY" "$NUM_REPITIONS" "$NUM_PODS" "$NUM_POLICIES" "$FORTIO_CLIENT_HOST_NAME" "$FORTIO_SERVER_HOST_NAME"
}

setup() {
    ./scripts/manage-cilium.sh deploy-cilium
    kubectl wait --for=condition=ready pods --all -n kube-system --timeout=60s
    if [ "$1" == "istio" ]; then
        ./scripts/manage-istio.sh deploy-istio
        kubectl wait --for=condition=ready pods --all -n kube-system --timeout=60s
    fi
}

teardown() {
    ./scripts/manage-cilium.sh remove-cilium
    if [ "$1" == "istio" ]; then
        ./scripts/manage-istio.sh remove-istio
        kubectl wait --for=condition=ready pods --all -n kube-system --timeout=60s
    fi
}

setup $2
case "$1" in 
    latenz)
        latenz $2 $3 $4
        ;;
    durchsatz)
        durchsatz $2 $3 $4
        ;;
    richtlinien-skalierbarkeit)
        richtlinien_skalierbarkeit $2 $3 $4
        ;;
    pod-skalierbarkeit)
        pod_skalierbarkeit $2 $3 $4
        ;;
    alle-messungen)
        latenz $2 $3 $4
        durchsatz $2 $3 $4
        richtlinien_skalierbarkeit $2 $3 $4
        pod_skalierbarkeit $2 $3 $4
        ;;
    *)
        echo "provide valid command"
        exit 1
        ;;
esac
teardown $2

#gke-netzwerkrichtlinien--default-pool-65ce6097-qcsh gke-netzwerkrichtlinien--default-pool-65ce6097-vrwb