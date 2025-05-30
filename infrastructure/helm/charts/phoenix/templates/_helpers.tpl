{{/*
Expand the name of the chart.
*/}}
{{- define "phoenix.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "phoenix.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "phoenix.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "phoenix.labels" -}}
helm.sh/chart: {{ include "phoenix.chart" . }}
{{ include "phoenix.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: phoenix
{{- end }}

{{/*
Selector labels
*/}}
{{- define "phoenix.selectorLabels" -}}
app.kubernetes.io/name: {{ include "phoenix.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "phoenix.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "phoenix.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Dashboard labels
*/}}
{{- define "phoenix.dashboard.labels" -}}
{{ include "phoenix.labels" . }}
app.kubernetes.io/component: dashboard
{{- end }}

{{/*
Dashboard selector labels
*/}}
{{- define "phoenix.dashboard.selectorLabels" -}}
{{ include "phoenix.selectorLabels" . }}
app.kubernetes.io/component: dashboard
{{- end }}

{{/*
API Gateway labels
*/}}
{{- define "phoenix.apiGateway.labels" -}}
{{ include "phoenix.labels" . }}
app.kubernetes.io/component: api-gateway
{{- end }}

{{/*
API Gateway selector labels
*/}}
{{- define "phoenix.apiGateway.selectorLabels" -}}
{{ include "phoenix.selectorLabels" . }}
app.kubernetes.io/component: api-gateway
{{- end }}

{{/*
Experiment Controller labels
*/}}
{{- define "phoenix.experimentController.labels" -}}
{{ include "phoenix.labels" . }}
app.kubernetes.io/component: experiment-controller
{{- end }}

{{/*
Experiment Controller selector labels
*/}}
{{- define "phoenix.experimentController.selectorLabels" -}}
{{ include "phoenix.selectorLabels" . }}
app.kubernetes.io/component: experiment-controller
{{- end }}

{{/*
Create image pull secret
*/}}
{{- define "phoenix.imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "phoenix.image" -}}
{{- $registryName := .imageRoot.registry -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $tag := .imageRoot.tag | toString -}}
{{- if .global }}
    {{- if .global.imageRegistry }}
        {{- $registryName = .global.imageRegistry -}}
    {{- end -}}
{{- end -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else -}}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end -}}
{{- end -}}

{{/*
Return the PostgreSQL secret name
*/}}
{{- define "phoenix.postgresql.secretName" -}}
{{- if .Values.postgresql.auth.existingSecret -}}
    {{- .Values.postgresql.auth.existingSecret -}}
{{- else -}}
    {{- printf "%s-postgresql" (include "phoenix.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the New Relic secret name
*/}}
{{- define "phoenix.newrelic.secretName" -}}
{{- if .Values.newrelic.apiKey.secretName -}}
    {{- .Values.newrelic.apiKey.secretName -}}
{{- else -}}
    {{- printf "%s-newrelic" (include "phoenix.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the pipeline operator service account
*/}}
{{- define "phoenix.pipelineOperatorServiceAccountName" -}}
{{- if .Values.pipelineOperator.serviceAccount.create }}
{{- default (printf "%s-pipeline-operator" (include "phoenix.fullname" .)) .Values.pipelineOperator.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.pipelineOperator.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the loadsim operator service account
*/}}
{{- define "phoenix.loadsimOperatorServiceAccountName" -}}
{{- if .Values.loadsimOperator.serviceAccount.create }}
{{- default (printf "%s-loadsim-operator" (include "phoenix.fullname" .)) .Values.loadsimOperator.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.loadsimOperator.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the database URL
*/}}
{{- define "phoenix.databaseURL" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "postgres://%s:%s@%s-postgresql:%d/%s?sslmode=disable" .Values.postgresql.auth.username .Values.postgresql.auth.password (include "phoenix.fullname" .) (.Values.postgresql.containerPorts.postgresql | int) .Values.postgresql.auth.database }}
{{- else }}
{{- .Values.externalDatabase.url }}
{{- end }}
{{- end }}

{{/*
Create the Redis URL
*/}}
{{- define "phoenix.redisURL" -}}
{{- if .Values.redis.enabled }}
{{- printf "redis://:%s@%s-redis-master:%d/0" .Values.redis.auth.password (include "phoenix.fullname" .) (.Values.redis.master.service.ports.redis | int) }}
{{- else }}
{{- .Values.externalRedis.url }}
{{- end }}
{{- end }}

{{/*
Return the API URL for internal communication
*/}}
{{- define "phoenix.apiURL" -}}
{{- printf "http://%s-api:%d" (include "phoenix.fullname" .) (.Values.api.service.port | int) -}}
{{- end -}}

{{/*
Return the generator URL for internal communication
*/}}
{{- define "phoenix.generatorURL" -}}
{{- printf "%s-generator:%d" (include "phoenix.fullname" .) (.Values.generator.service.grpcPort | int) -}}
{{- end -}}