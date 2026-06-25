### `hlib.httpRoute` template

Creates Kubernetes Gateway API HTTPRoute manifest.

#### Basic Usage

Include this template in your chart's `templates/httproute.yaml`:

```handlebars
{{- include "hlib.httpRoute" (dict "context" .) }}
```

Add the following values

```yaml
httpRoute:
  parentRefs:
    - name: gateway
      namespace: gateway-system
      sectionName: https
  hostnames:
    - app.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
    - matches:
        - path:
            type: PathPrefix
            value: /static
      backendRefs:
        - name: static-service
          port: 80
```

Rules without `backendRefs` automatically route traffic to the chart's Service.

#### Configuration

| Parameter      | Description                                                               | Required | Default             |
|----------------|---------------------------------------------------------------------------|----------|---------------------|
| `context`      | Root Helm context (usually `.`)                                           | Yes      | -                   |
| `values`       | HTTPRoute configuration values (from `values.yaml`)                       | No       | `.Values.httpRoute` |
| `dependencies` | Dictionary of dependent components (see below)                            | No       | -                   |
| `override`     | Name of a template that overrides the basic one configured in the library | No       | -                   |

**Dependency Integration**

Used to override the configuration path of resources on which it depends.

| Dependency | Usage                  | Default           |
|------------|------------------------|-------------------|
| `service`  | Service name injection | `.Values.service` |

```handlebars
{{- $dependencies := dict "service" .Values.newService -}}
{{- include "hlib.httpRoute" (dict "context" . "dependencies" $dependencies) }}
```

#### Advanced: Template Overrides

The changes can only be added to the HTTPRoute base template via `override` parameter as follows:

```handlebars
{{- include "hlib.httpRoute" (dict "context" . "override" "app.httpRoute") -}}

{{- define "app.httpRoute" -}}
metadata:
  name: {{ printf "%s-ui" (include "hlib.fullname" $) | trunc 63 | trimSuffix "-" }}
{{- end -}}
```
