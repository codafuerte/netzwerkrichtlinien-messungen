#!/bin/bash

install_istioctl() {
  # see https://istio.io/latest/docs/setup/getting-started/
  echo "Start installing Istio..."
  echo "Downloading Istio 1.13.2"
  curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.13.2 TARGET_ARCH=x86_64 sh -
  echo "Installing Istioctl"
  sudo install istio-1.13.2/bin/istioctl /usr/local/bin/
  echo  "Installation of istioctl succesful: $(istioctl version)"
  rm istio-1.13.2-linux-amd64.tar.gz && rm -R istio-1.13.2
}

deploy_istio() {
  echo "Deploying Istio with default kubectl-configuration"
  istioctl install --set profile=default -y
  echo  "Installation of istioctl succesful: $(istioctl version)"
  echo "Injecting Istio to the default namespace"
  kubectl label namespace default istio-injection=enabled
  echo "To activate the istio features use kubectl and yaml-Files"
}

remove_istio() {
  echo "remove istio from cluster"
  istioctl manifest generate --set profile=demo | kubectl delete --ignore-not-found=true -f -
  istioctl tag remove default
  kubectl delete namespace istio-system
  kubectl delete namespace istio-system
}

case "$1" in 
    install-istioctl)
        install_istioctl
        exit 0
        ;;
    deploy-istio)
        deploy_istio 
        exit 0
        ;;
    remove-istio)
        remove_istio 
        exit 0
        ;;
    *)
        echo "provide valid command"
        exit 1
        ;;
esac