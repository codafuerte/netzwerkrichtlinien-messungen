#!/bin/bash
create_cilium_policy() {
    cat<<YAML >./richtlinien/s2s/cilium/policy$1.yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "cilium-policy$1"
spec:
  description: "Allow only HTTP POST /$( if [ $1 != $2 ]; then echo "/$1"; fi ) from fortio-client to fortio-server"
  endpointSelector:
    matchLabels:
      app: bestell
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: fortio
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
      rules:
        http:
        - method: "POST"
          path: "/$( if [ $1 != $2 ]; then echo "$1"; fi )"
YAML
}

create_istio_policy() {
    cat<<YAML >./richtlinien/s2s/istio/policy$1.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: istio-policy$1
 namespace: default
spec:
 selector:
   matchLabels:
     app: fortio-server
     version: v1
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/fortio-client"]
   to:
   - operation:
       ports: ["8080"]
       methods: ["POST"]
       paths: ["/$( if [ $1 != $2 ]; then echo "$1"; fi )"]
YAML
}

create_policy() {
    if [ ! -d "richtlinien" ]; then
        mkdir richtlinien
    fi

    if [ ! -d "richtlinien/s2s" ]; then
        mkdir richtlinien/s2s
    fi

    if [ ! -d "richtlinien/s2s/$1" ]; then
        mkdir richtlinien/s2s/$1
    fi
    
    case "$1" in
        cilium)
            create_cilium_policy $2 $3
            ;;
        istio)
            create_istio_policy $2 $3
            ;;
    esac
}

deploy_policy() {
    kubectl apply -f ./richtlinien/s2s/$1/policy$2.yaml
}

delete_policy() {
    kubectl delete -f ./richtlinien/s2s/$1/policy$2.yaml
    rm ./richtlinien/s2s/$1/policy$2.yaml
}

if [ "$2" != "cilium" ] && [ "$2" != "istio" ]; then
    echo "Make sure to set 'cilium' or 'istio'"
    exit 1
fi

for i in `seq 1 $3`
do
    case "$1" in
    create-policies)
        create_policy $2 $i $3
        ;;
    deploy-policies)
        deploy_policy $2 $i $3
        ;;
    create-and-deploy-policies)
        create_policy $2 $i $3
        deploy_policy $2 $i $3
        ;;
    delete-policies)
        delete_policy $2 $i
        ;;
    *)
        echo "Make sure to set a valid command"
        exit 1
        ;;
    esac
done