#!/usr/bin/env sh
set -e

echo "Registering Consul DNS entries"

for service in $@ 
do
  echo "Registering service: ${service}"
  wget -S -O- --header='Content-Type: application/json' \
    --post-data  "{\"Name\":\"${service}\",\"Service\":\"${service}\",\"Address\":\"{{ .Values.ingressIP }}\",\"Port\":80}" \
    http://{{ .Values.consulIP }}:8500/v1/agent/service/register
done
