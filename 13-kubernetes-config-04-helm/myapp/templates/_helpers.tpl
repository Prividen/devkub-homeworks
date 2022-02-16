{{- define "useVer" -}}
{{- default .Chart.AppVersion .Values.AppVersionOverride }}
{{- end }}

{{- define "safeVer" -}}
{{- include "useVer" . | replace "." "-" | trunc 63 | trimSuffix "-" }}
{{- end }}

