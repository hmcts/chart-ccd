{{/*
Override the upstream Logstash ServiceAccount-name helper.
Evaluate configured names as templates, while preserving the upstream
resource-name fallback when no name is supplied.
*/}}
{{- define "logstash.serviceAccount" -}}
{{- tpl (.Values.rbac.serviceAccountName | default (include "logstash.fullname" .)) . -}}
{{- end -}}