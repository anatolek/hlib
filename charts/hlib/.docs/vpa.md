### `hlib.vpa` template

Creates Kubernetes VerticalPodAutoscaler resources (`autoscaling.k8s.io/v1`).

> Requires the [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) controller and its CRDs to be installed in the cluster.

By default, the autoscaler targets the chart `Deployment`.

#### Basic Usage

Include this template in your chart's `templates/vpa.yaml`:

```handlebars
{{- include "hlib.vpa" (dict "context" .) }}
```

Add the following values

```yaml
vpa:
  updatePolicy:
    updateMode: "Recreate"
  resourcePolicy:
    containerPolicies:
      - containerName: "*"
        minAllowed:
          cpu: 50m
          memory: 64Mi
        maxAllowed:
          cpu: "1"
          memory: 512Mi
        controlledResources: ["cpu", "memory"]
```

#### Configuration

| Parameter      | Description                                                               | Required | Default       |
|----------------|---------------------------------------------------------------------------|----------|---------------|
| `context`      | Root Helm context (usually `.`)                                           | Yes      | -             |
| `values`       | Vertical Pod Autoscaler configuration values (from `values.yaml`)         | No       | `.Values.vpa` |
| `dependencies` | Dictionary of dependent components (see below)                            | No       | -             |
| `override`     | Name of a template that overrides the basic one configured in the library | No       | -             |

**Dependency Integration**

Used to override the configuration path of resources on which it depends.
The dependency is only used to resolve the default `targetRef` and is ignored when `vpa.targetRef` is set explicitly.

| Dependency   | Usage                | Default              |
|--------------|----------------------|----------------------|
| `deployment` | Deployment reference | `.Values.deployment` |

```handlebars
{{- $dependencies := dict "deployment" .Values.newDeployment -}}
{{- include "hlib.vpa" (dict "context" . "dependencies" $dependencies) }}
```

**Custom target reference**

By default the VPA targets the chart `Deployment`. Point it to another controller (e.g. `StatefulSet`) with `vpa.targetRef`:

```yaml
vpa:
  targetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: my-statefulset
```

#### Advanced: Template Overrides

The changes can only be added to the base template via `override` parameter, e.g.:

```handlebars
{{- include "hlib.vpa" (dict "context" . "override" "app.vpa") -}}

{{- define "app.vpa" -}}
spec:
  updatePolicy:
    updateMode: "Initial"
{{- end -}}
```
