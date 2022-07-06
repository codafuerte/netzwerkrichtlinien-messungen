#!/bin/bash

QPS_KEY="--qps="
DURATION_KEY="--duration="
CONNECTIONS_KEY="--connections="
NUM_CALLS_KEY="--num-calls="
SERVER_ADDRESS_KEY="--server-address="
PORT_KEY="--port="
OUTPUT_KEY="--output="
PATH_KEY="--path="
CONTENT_TYPE_KEY="--content-type="
PAYLOAD_KEY="--payload="

while [ $# -gt 0 ]; do
  echo $1
  case "$1" in
    $QPS_KEY*)
      QPS_VALUE="${1:${#QPS_KEY}}"
      ;;
    $DURATION_KEY*)
      DURATION_VALUE="${1:${#DURATION_KEY}}"
      ;;
    $CONNECTIONS_KEY*)
      CONNECTIONS_VALUE="${1:${#CONNECTIONS_KEY}}"
      ;;
    $NUM_CALLS_KEY*)
      NUM_CALLS_VALUE="${1:${#NUM_CALLS_KEY}}"
      ;;
    $SERVER_ADDRESS_KEY*)
      SERVER_ADDRESS_VALUE="${1:${#SERVER_ADDRESS_KEY}}"
      ;;
    $PORT_KEY*)
      PORT_VALUE="${1:${#PORT_KEY}}"
      ;;
    $OUTPUT_KEY*)
      OUTPUT_VALUE="${1:${#OUTPUT_KEY}}"
      ;;
    $PATH_KEY*)
      PATH_VALUE="${1:${#PATH_KEY}}"
      ;;
    $CONTENT_TYPE_KEY*)
      CONTENT_TYPE_VALUE="${1:${#CONTENT_TYPE_KEY}}"
      ;;
    $PAYLOAD_KEY*)
      PAYLOAD_VALUE="${1:${#PAYLOAD_KEY}}"
      ;;
    *)
      echo "Make sure to set valid arguments: --qps= --connections= --num-calls= --duration= --server-address= --port= --output= --path= --content-type= --payload="
      exit 1
      ;;
  esac
  shift
done

if [ -z $QPS_VALUE ]; then
    echo "--qps must be set (e.g. --qps=0)"
    exit 1
fi

if [ -z $DURATION_VALUE ] && [ -z $NUM_CALLS_VALUE ]; then
    echo "either --duration or --num-calls must be set (e.g. --duration=5s)"
    exit 1
fi

if [ ! -z $DURATION_VALUE ] && [ ! -z $NUM_CALLS_VALUE ]; then
    echo "either --duration or --num-calls must be set (e.g. --duration=5s)"
    exit 1
fi

if [ -z $CONNECTIONS_VALUE ]; then
    echo "--connections must be set (e.g. --qps=4)"
    exit 1
fi

if [ -z $SERVER_ADDRESS_VALUE ]; then
    echo "--server-address must be set (e.g. --server-address=fortio-server)"
    exit 1
fi

if [ -z $PORT_VALUE ]; then
    echo "--port must be set (e.g. --port=8000)"
    exit 1
fi

if [ -z $OUTPUT_VALUE ]; then
    echo "--output must be set (e.g. --output=testmessungen)"
    exit 1
fi

FORTIO_POD_NAME=$( kubectl get pods --template '{{range .items}}{{.metadata.name}}{{end}}' --selector=app=fortio-client )
DAY=$( date +%Y-%m-%d )

if [ ! -d "ergebnisse" ]; then
  mkdir ergebnisse
fi

if [ ! -d "ergebnisse/${DAY}" ]; then
  mkdir ergebnisse/${DAY}
fi

echo $( kubectl exec $FORTIO_POD_NAME -c fortio-client -- /usr/bin/fortio load -qps $QPS_VALUE $( if [ ! -z $DURATION_VALUE ]; then echo "-t $DURATION_VALUE"; else echo "-n $NUM_CALLS_VALUE"; fi ) -c $CONNECTIONS_VALUE -json -$( if [ ! -z $PAYLOAD_VALUE ]; then echo " -payload '$PAYLOAD_VALUE' "; fi )$( if [ ! -z $CONTENT_TYPE_VALUE ]; then echo " -content-type $CONTENT_TYPE_VALUE "; fi )http://$SERVER_ADDRESS_VALUE:$PORT_VALUE/$PATH_VALUE ) | cat> ./ergebnisse/${DAY}/${OUTPUT_VALUE}.json