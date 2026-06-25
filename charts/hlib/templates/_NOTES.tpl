{{- define "hlib.notes.chartInfo" }}
{{- $ := .context }}
CHART NAME: {{ $.Chart.Name }}
CHART VERSION: {{ $.Chart.Version }}
APP VERSION: {{ $.Chart.AppVersion }}
{{- if $.Chart.Sources }}
SOURCES:
{{- range $.Chart.Sources }}
  - {{ . }}
{{- end }}
{{- println "" }}
{{- end }}
{{- end }}

{{- define "hlib.notes.releaseInfo" }}
{{- $ := .context }}
RELEASE NAME: {{ $.Release.Name }}
NAMESPACE: {{ $.Release.Namespace }}
REVISION: {{ $.Release.Revision }}
{{- println "" }}
{{- end }}

{{- define "hlib.notes.accessAppInfo.labels" -}}
{{- $raw := include "hlib.selectorLabels" . | trim | splitList "\n" -}}
{{- range $index, $line := $raw -}}
  {{- if $index }},{{ end }}
  {{- $parts := splitList ": " $line -}}
  {{- index $parts 0 }}={{ index $parts 1 }}
{{- end }}
{{- end }}

{{- define "hlib.notes.accessAppInfo" -}}
{{- $ := .context -}}
{{- $hr := .httpRoute | default $.Values.httpRoute -}}
{{- $ing := .ingress | default $.Values.ingress -}}
{{- $svc := .service | default $.Values.service -}}
{{- $svcType := $svc.type | default "ClusterIP" -}}
{{- $svcPort := $svc.port | default 80 -}}

{{- if and $hr.enabled $hr.hostnames $hr.rules }}
**Access application via HTTPRoute:**

   {{- $useHttps := false }}
   {{- range $hr.parentRefs }}
   {{- if eq (.sectionName | default "") "https" }}
   {{- $useHttps = true }}
   {{- end }}
   {{- end }}
   {{- range $hr.hostnames }}
   {{- $host := . }}
   {{- range $hr.rules }}
   {{- range .matches }}
   {{- if .path }}
   http{{ if $useHttps }}s{{ end }}://{{ $host }}{{ .path.value | default "/" }}
   {{- else }}
   http{{ if $useHttps }}s{{ end }}://{{ $host }}/
   {{- end }}
   {{- end }}
   {{- end }}
   {{- end }}

   Make sure your DNS is configured to resolve these hostnames to the Gateway's external address.

{{- else if and $ing.enabled $ing.hosts }}
**Access application via Ingress:**

   {{- range $ing.hosts }}
   {{- $host := .host | default "" }}
   {{- range .paths }}
   http{{ if $ing.tls }}s{{ end }}://{{ $host }}{{ .path }}
   {{- end }}
   {{- end }}

   Make sure your DNS is configured to resolve these hostnames to the Ingress controller's external IP.

{{- else if contains "NodePort" $svcType }}
**Access application via Kubernetes node port:**

  export NODE_PORTS=$(kubectl get svc --namespace {{ $.Release.Namespace }} -l "{{ include "hlib.notes.accessAppInfo.labels" $ }}" -o jsonpath='{.items[*].spec.ports[*].nodePort})
  export NODE_IP=$(kubectl get nodes --namespace {{ $.Release.Namespace }} -o jsonpath="{.items[0].status.addresses[0].address}")
  echo $NODE_PORTS | xargs -n1 -I{} echo "http://$NODE_IP:{}"
{{- else if contains "LoadBalancer" $svcType }}
**Access application via service external Load Balancer:**

     NOTE: It may take a few minutes for the LoadBalancer IP to be available.
           You can watch the status of by running 'kubectl get svc --namespace {{ $.Release.Namespace }} -w -l "{{ include "hlib.notes.accessAppInfo.labels" $ }}"'
  export SERVICE_IP=$(kubectl get svc --namespace {{ $.Release.Namespace }} -l "{{ include "hlib.notes.accessAppInfo.labels" $ }}" --template "{{"{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}"}}")
  echo http://$SERVICE_IP:{{ $svcPort }}
{{- else if contains "ClusterIP" $svcType }}
**Access application via Kubernetes service:**

  export POD_NAME=$(kubectl get pods --namespace {{ $.Release.Namespace }} -l "{{ include "hlib.notes.accessAppInfo.labels" $ }}" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace {{ $.Release.Namespace }} $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  kubectl --namespace {{ $.Release.Namespace }} port-forward $POD_NAME 8080:$CONTAINER_PORT
  echo "Visit http://127.0.0.1:8080 to use your application"
{{- end }}

{{- if and (hasKey $ing "enabled") (not $ing.enabled) }}
{{- println "" }}
> Note: Ingress is disabled.
{{- end }}
{{- if and (hasKey $hr "enabled") (not $hr.enabled) }}
{{- println "" }}
> Note: HTTPRoute is disabled.
{{- end }}
{{- println "" }}
{{- end }}

{{- define "hlib.notes.diagnosticMode" }}
{{- $ := .context }}
**DEBUG MODE IS ENABLED**

Ask the cluster admins to run the following commands and provide the kubeconfig for kubernetes cluster access:

# Get current context
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}' | cut -d'/' -f2)
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
TOKEN=$(kubectl get secret {{ printf "%s-debug" (include "hlib.fullname" $) | trunc 63 | trimSuffix "-" }} -o jsonpath='{.data.token}' | base64 -d)

cat <<EOF > debug-kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    server: ${CLUSTER_SERVER}
    certificate-authority-data: ${CLUSTER_CA}
contexts:
- name: ${CLUSTER_NAME}-debug
  context:
    cluster: ${CLUSTER_NAME}
    user: {{ printf "%s-debug" (include "hlib.fullname" $) | trunc 63 | trimSuffix "-" }}
    namespace: {{ $.Release.Namespace }}
current-context: ${CLUSTER_NAME}-debug
users:
- name: {{ printf "%s-debug" (include "hlib.fullname" $) | trunc 63 | trimSuffix "-" }}
  user:
    token: ${TOKEN}
EOF
{{- println "" }}
{{- end }}
