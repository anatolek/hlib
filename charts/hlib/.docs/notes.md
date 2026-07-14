### `hlib.notes` templates

Provides post-installation information for users, including access instructions and debug mode setup.

#### Basic Usage

Include this template in your chart's `templates/_NOTES.txt`:

```handlebars
{{- include "hlib.notes.chartInfo" (dict "context" .) }}

{{- include "hlib.notes.releaseInfo" (dict "context" .) }}

{{- include "hlib.notes.accessAppInfo" (dict "context" .) }}

{{- if .Values.diagnosticMode.enabled }}
{{- include "hlib.notes.diagnosticMode" (dict "context" .) }}
{{- end }}
```

#### Chart Information

```handlebars
{{- include "hlib.notes.chartInfo" (dict "context" .) }}
```

Output Example:

```yaml
CHART NAME: my-app
CHART VERSION: 1.2.3
APP VERSION: v4.5.0
SOURCES:
  - https://github.com/my-org/my-app
```

#### Release Information

```handlebars
{{- include "hlib.notes.releaseInfo" (dict "context" .) }}
```

Output Example:

```yaml
RELEASE NAME: my-app-dev
NAMESPACE: production
REVISION: 2
```

#### Application Access Instructions

```handlebars
{{- include "hlib.notes.accessAppInfo" (dict "context" .) }}
```

Output Depends on Configuration:

| Service Type  | 	Example Output                                            |
|---------------|-------------------------------------------------------------|
| HTTPRoute     | Access application via HTTPRoute: https://app.example.com/  |
| Ingress       | Access application via Ingress: https://app.example.com/api |
| NodePort	    | Provides kubectl commands to retrieve node IP and ports     |
| LoadBalancer	| Provides commands to get LB IP and port                     |
| ClusterIP     | Provides port-forward command for local access              |

#### Diagnostic Mode Setup

```handlebars
{{- include "hlib.notes.diagnosticMode" (dict "context" .) }}
```

Output When Debug Enabled:

```plaintext
DEBUG MODE IS ENABLED

Ask cluster admins to run these commands:
# Get current context
CLUSTER_NAME=...
# Creates debug-kubeconfig.yaml with temporary access token
```

#### Customization Options

Override Service/Ingress/HTTPRoute References

```handlebars
{{- include "hlib.notes.accessAppInfo" (dict "context" . "service" .Values.customService "ingress" .Values.specialIngress "httpRoute" .Values.customHttpRoute) }}
```
