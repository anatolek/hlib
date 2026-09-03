### `hlib.podMonitor` template

Creates Prometheus Operator PodMonitor resources (`monitoring.coreos.com/v1`). A PodMonitor
discovers Pods directly, without requiring a Service, and configures how Prometheus scrapes
their endpoints.

> Requires the [Prometheus Operator](https://prometheus-operator.dev/) and its CRDs to be installed in the cluster.

By default, the monitor selects the chart Pods using `hlib.selectorLabels` and scrapes
their `cont-tcp-port` port. The full `podMonitor.spec` object is rendered as-is, so any
field supported by the installed Prometheus Operator version can be configured.

#### Basic Usage

Include this template in your chart's `templates/pod-monitor.yaml`:

```handlebars
{{- include "hlib.podMonitor" (dict "context" .) }}
```

Optionally add labels used by the Prometheus instance to discover the PodMonitor and
customize the scrape endpoint:

```yaml
podMonitor:
  labels:
    release: kube-prometheus-stack
  spec:
    podMetricsEndpoints:
      - port: cont-tcp-port
        path: /metrics
        interval: 30s
```

#### Configuration

| Parameter  | Description                                                               | Required | Default              |
|------------|---------------------------------------------------------------------------|----------|----------------------|
| `context`  | Root Helm context (usually `.`)                                           | Yes      | -                    |
| `values`   | PodMonitor configuration values (from `values.yaml`)                      | No       | `.Values.podMonitor` |
| `override` | Name of a template that overrides the basic one configured in the library | No       | -                    |

`podMonitor.labels` are merged over the standard `hlib.labels`. The `podMonitor.spec`
value accepts the upstream
[PodMonitorSpec](https://prometheus-operator.dev/docs/api-reference/api/#monitoring.coreos.com/v1.PodMonitorSpec),
including selectors, namespace selection, scrape endpoints, relabeling, authentication,
limits, and protocol settings. Explicit `spec.selector` or `spec.podMetricsEndpoints`
values replace the defaults, including explicit empty objects or lists.

#### Advanced: Template Overrides

Additional fields can be merged into the base template with the `override` parameter:

```handlebars
{{- include "hlib.podMonitor" (dict "context" . "override" "app.podMonitor") -}}

{{- define "app.podMonitor" -}}
metadata:
  labels:
    monitoring-tier: platform
{{- end -}}
```
