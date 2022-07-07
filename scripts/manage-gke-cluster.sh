#!/bin/bash

GKE_CLUSTER_VERSION="1.22.8-gke.202"
GKE_CLUSTER_NAME="netzwerkrichtlinien-messungen-cluster"
ZONE="us-central1-a"
MACHINE_TYPE="n2-standard-4"

create_gke_cluster() {
    NUM_NODES=$1

    if [ -z $NUM_NODES ]; then
        echo "number of nodes must be set"
        exit 1
    fi

    gcloud container clusters create "${GKE_CLUSTER_NAME}" \
        --node-taints node.cilium.io/agent-not-ready=true:NoExecute \
        --cluster-version "${GKE_CLUSTER_VERSION}" \
        --machine-type="${MACHINE_TYPE}" \
        --num-nodes="${NUM_NODES}" \
        --zone "${ZONE}"
    gcloud container clusters get-credentials "${GKE_CLUSTER_NAME}" --zone "${ZONE}"
}

delete_gke_cluster() {
    gcloud container clusters delete "${GKE_CLUSTER_NAME}" --zone "${ZONE}"
}

case "$1" in 
    create-gke-cluster)
        create_gke_cluster $2
        exit 0
        ;;
    delete-gke-cluster)
        delete_gke_cluster $2
        exit 0
        ;;
    *)
        echo "provide valid command"
        exit 1
        ;;
esac