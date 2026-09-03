### `hlib.serviceMonitor` template

Creates Prometheus Operator ServiceMonitor resources (`monitoring.coreos.com/v1`). A
ServiceMonitor discovers Services and configures how Prometheus scrapes their endpoints.

> Requires the [Prometheus Operator](https://prometheus-operator.dev/) and its CRDs to be installed in the cluster.

By default, the monitor selects the chart Service using `hlib.selectorLabels` and scrapes
its `svc-tcp-port` port. The full `serviceMonitor.spec` object is rendered as-is, so any
field supported by the installed Prometheus Operator version can be configured.

#### Basic Usage

Include this template in your chart's `templates/service-monitor.yaml`:

```handlebars
{{- include "hlib.serviceMonitor" (dict "context" .) }}
```

Optionally add labels used by the Prometheus instance to discover the ServiceMonitor and
customize the scrape endpoint:

```yaml
serviceMonitor:
  labels:
    release: kube-prometheus-stack
  spec:
    endpoints:
      - port: svc-tcp-port
        path: /metrics
        interval: 30s
```

#### Configuration

| Parameter  | Description                                                               | Required | Default                  |
|------------|---------------------------------------------------------------------------|----------|--------------------------|
| `context`  | Root Helm context (usually `.`)                                           | Yes      | -                        |
| `values`   | ServiceMonitor configuration values (from `values.yaml`)                  | No       | `.Values.serviceMonitor` |
| `override` | Name of a template that overrides the basic one configured in the library | No       | -                        |

`serviceMonitor.labels` are merged over the standard `hlib.labels`. The
`serviceMonitor.spec` value accepts the upstream
[ServiceMonitorSpec](https://prometheus-operator.dev/docs/api-reference/api/#monitoring.coreos.com/v1.ServiceMonitorSpec),
including selectors, namespace selection, scrape endpoints, relabeling, authentication,
limits, and protocol settings. Explicit `spec.selector` or `spec.endpoints` values replace
the defaults, including explicit empty objects or lists.

#### Advanced: Template Overrides

Additional fields can be merged into the base template with the `override` parameter:

```handlebars
{{- include "hlib.serviceMonitor" (dict "context" . "override" "app.serviceMonitor") -}}

{{- define "app.serviceMonitor" -}}
metadata:
  labels:
    monitoring-tier: platform
{{- end -}}
```
