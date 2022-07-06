#!/bin/bash

ROLE_KEY="--role="
HOST_NAME_KEY="--host-name="
NUM_PODS_KEY="--num-pods="

COMMAND=$1

while [ $# -gt 1 ]; do
  case "$2" in
    $ROLE_KEY*)
      ROLE_VALUE="${2:${#ROLE_KEY}}"
      ;;
    $HOST_NAME_KEY*)
      HOST_NAME_VALUE="${2:${#HOST_NAME_KEY}}"
      ;;
    $NUM_PODS_KEY*)
      NUM_PODS_VALUE="${2:${#NUM_PODS_KEY}}"
      ;;
    *)
      echo "Make sure to set valid arguments: --role --host-name --num-pods"
      exit 1
      ;;
  esac
  shift
done

if [ "$ROLE_VALUE" != "client" ] && [ "$ROLE_VALUE" != "server" ]; then
    echo "Make sure to set 'client' or 'server'"
    exit 1
fi

deploy_fortio() {

    if [ -z "$HOST_NAME_VALUE" ]; then
        echo "Make sure to set hostname, to which fortio should be deployed"
        exit 1
    fi

    sudo sed -i "s/kubernetes.io\/hostname:.*/kubernetes.io\/hostname: ${HOST_NAME_VALUE}/" kubernetes/fortio.${ROLE_VALUE}.deployment.yaml
    kubectl apply -f kubernetes/fortio.${ROLE_VALUE}.deployment.yaml 
}

scale_fortio() {

    if [ -z "$NUM_PODS_VALUE" ]; then
        echo "Make sure to set the desired number of pods"
        exit 1
    fi

    kubectl scale deployment/fortio-${ROLE_VALUE}-deployment --replicas=${NUM_PODS_VALUE}
}

remove_fortio() {
    kubectl delete -f kubernetes/fortio.${ROLE_VALUE}.deployment.yaml 
}

case "$COMMAND" in 
    deploy-fortio)
        deploy_fortio
        exit 0
        ;;
    remove-fortio)
        remove_fortio
        exit 0
        ;;
    scale-fortio)
        scale_fortio
        exit 0
        ;;
    *)
        echo "Make sure to set valid command: deploy-fortio, remove-fortio, scale-fortio"
        exit 1
        ;;
esac