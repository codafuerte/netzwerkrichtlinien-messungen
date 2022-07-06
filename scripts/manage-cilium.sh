#!/bin/bash

install_cilium_cli() {
    echo "download cilium-cli tar file & checksum file" 
    curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
    echo "Checking checksum"
    sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
    echo "unpack cilium-cli tar file"
    sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
    rm cilium-linux-amd64.tar.gz && rm cilium-linux-amd64.tar.gz.sha256sum
}

install_helm() {
    echo "downloading helm-tar file"
    curl -O -L https://get.helm.sh/helm-v3.9.0-linux-amd64.tar.gz
    echo "unpack tar-file"
    sudo tar -zxvf helm-v3.9.0-linux-amd64.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm helm-v3.9.0-linux-amd64.tar.gz && sudo rm -r linux-amd64
}

remove_cilium() {
    echo "Remove Cilium from cluster"
    cilium uninstall
}

deploy_cilium() {
    GKE_CLUSTER_NAME="netzwerkrichtlinien-messungen-cluster"
    ZONE="us-central1-a"    
    case "$1" in 
        helm)
            echo "setup helm repository"
            helm repo add cilium https://helm.cilium.io/
            echo "Extract the Cluster CIDR to enable native-routing:"
            NATIVE_CIDR="$(gcloud container clusters describe "${GKE_CLUSTER_NAME}" --zone "${ZONE}" --format 'value(clusterIpv4Cidr)')"
            echo "deploy Cilium to Cluster"
            helm install cilium cilium/cilium --version 1.11.6 \
                --namespace kube-system \
                --set bpf.policyMapMax=32768 \
                --set nodeinit.enabled=true \
                --set nodeinit.reconfigureKubelet=true \
                --set nodeinit.removeCbrBridge=true \
                --set cni.binPath=/home/kubernetes/bin \
                --set gke.enabled=true \
                --set ipam.mode=kubernetes \
                --set ipv4NativeRoutingCIDR=$NATIVE_CIDR
            exit 0
            ;;
        cilium-cli)
            echo "deploy Cilium to Cluster"
            cilium install --version 1.11.6
            exit 0
            ;;
        *)
            echo "Make sure to set 'helm' or 'cilium-cli'"
            exit 1
        ;;
    esac
}

case "$1" in 
    install-cilium-cli)
        install_cilium_cli
        exit 0
        ;;
    install-helm)
        install_helm
        exit 0
        ;;
    deploy-cilium)
        deploy_cilium $2
        exit 0
        ;;
    remove-cilium)
        remove_cilium $2
        exit 0
        ;;
    *)
        echo "provide valid command"
        exit 1
        ;;
esac
    