#!/usr/bin/env sh
set -e

echo "Registering Consul DNS entries"

for service in $@ 
do
  echo "Registering service: ${service}"
  curl -X PUT -H 'Content-Type: application/json' \
    -d "{\"Name\":\"${service}\",\"Service\":\"${service}\",\"Address\":\"{{ .Values.ingressIP }}\",\"Port\":80}" \
    http://{{ .Values.consulIP }}:8500/v1/agent/service/register
done
