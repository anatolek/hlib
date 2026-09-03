# monitoring

![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.0.1](https://img.shields.io/badge/AppVersion-0.0.1-informational?style=flat-square)

A Helm chart demonstrating Prometheus Operator monitors

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://anatolek.github.io/helm-charts | hlib | >= 0.0.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| podMonitor.enabled | bool | `false` | Create a PodMonitor that discovers the chart Pods directly. Disabled by default to avoid scraping the same target twice. |
| podMonitor.labels | object | `{"release":"kube-prometheus-stack"}` | Labels used by Prometheus to discover this PodMonitor. |
| podMonitor.spec | object | `{"podMetricsEndpoints":[{"interval":"30s","path":"/metrics","port":"cont-tcp-port"}]}` | PodMonitor scrape configuration. |
| serviceMonitor.enabled | bool | `true` | Create a ServiceMonitor that discovers the chart Service. |
| serviceMonitor.labels | object | `{"release":"kube-prometheus-stack"}` | Labels used by Prometheus to discover this ServiceMonitor. |
| serviceMonitor.spec | object | `{"endpoints":[{"interval":"30s","path":"/metrics","port":"svc-tcp-port"}]}` | ServiceMonitor scrape configuration. |
