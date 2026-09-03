### `hlib.service` template

Creates Kubernetes Service resources.

By default, a service with type `ClusterIP` is created on port 80 with `appProtocol: http`.

#### Basic Usage

Include this template in your chart's `templates/service.yaml`:

```handlebars
{{- include "hlib.service" (dict "context" .) }}
```

#### Configuration

| Parameter  | Description                                                               | Required | Default           |
|------------|---------------------------------------------------------------------------|----------|-------------------|
| `context`  | Root Helm context (usually `.`)                                           | Yes      | -                 |
| `values`   | Service configuration values (from `values.yaml`)                         | No       | `.Values.service` |
| `override` | Name of a template that overrides the basic one configured in the library | No       | -                 |

**Add additional ports for service**

If necessary, additional ports can be added via a special variable `service.extraPorts`

```yaml
service:
  extraPorts:
    - name: debug-port
      port: 5005
      targetPort: 5005
      protocol: TCP
```

#### Advanced: Template Overrides

The changes can only be added to the base template via `override` parameter, e.g.:

```handlebars
{{- include "hlib.service" (dict "context" . "override" "app.service") -}}

{{- define "app.service" -}}
spec:
  ports:
    - name: svc-tcp-port
      port: 80
      targetPort: cont-tcp-port
      protocol: TCP
    - name: admin-tcp-port
      port: 8787
      targetPort: 8787
      protocol: TCP
{{- end -}}
```
