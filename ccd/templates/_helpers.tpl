{{- define "importer.vault" }}
  {{- if .Values.global.subscriptionId == "bf308a5c-0624-4334-8ff8-8dca9fd43783"}}
  keyVaultName: "ccd-saat"
  resourceGroup: "ccd-shared-saat"
  {{- else }} }}
  keyVaultName: "ccd-aat"
  resourceGroup: "ccd-shared-aat"
  {{- end }}
{{- end }}

{{- define "importer.redirect" }}
  {{- if .Values.global.subscriptionId == "bf308a5c-0624-4334-8ff8-8dca9fd43783"}}
  - name: REDIRECT_URI
    value: : https://ccd-case-management-web-saat-staging.service.core-compute-saat.internal/oauth2redirect
  {{- else }} }}
  - name: REDIRECT_URI
    value: : https://ccd-case-management-web-preview.service.core-compute-preview.internal/oauth2redirect
  {{- end }}
{{- end }}
