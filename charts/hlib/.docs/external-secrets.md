### `hlib.externalSecrets` template

Creates [External Secrets Operator](https://external-secrets.io/) `ExternalSecret` resources (`external-secrets.io/v1`).

#### Basic Usage

Include this template in your chart's `templates/external-secret.yaml`:

```handlebars
{{- include "hlib.externalSecrets" (dict "context" .) }}
```

The spec is rendered from the `externalSecrets` values, e.g.:

```yaml
externalSecrets:
  refreshInterval: "1h"
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    creationPolicy: Owner
  data:
    - secretKey: token
      remoteRef:
        key: prod/app
        property: token
```

#### Configuration

| Parameter  | Description                                                               | Required | Default                  |
|------------|---------------------------------------------------------------------------|----------|--------------------------|
| `context`  | Root Helm context (usually `.`)                                           | Yes      | -                        |
| `values`   | ExternalSecret configuration values (from `values.yaml`)                  | No       | `.Values.externalSecrets`|
| `override` | Name of a template that overrides the basic one configured in the library | No       | -                        |

#### Advanced: Template Overrides

The changes can only be added to the base template via `override` parameter, e.g.:

```handlebars
{{- include "hlib.externalSecrets" (dict "context" . "override" "app.externalSecrets") -}}

{{- define "app.externalSecrets" -}}
spec:
  dataFrom:
    - extract:
        key: prod/app
{{- end -}}
```

#### External Secrets Operator templates

External Secrets Operator evaluates Go templates in fields such as
`target.template.data` and `dataFrom[].rewrite[].transform.template`. Because these
values also pass through Helm templating, escape the operator expression with a Helm
raw string so it reaches the `ExternalSecret` unchanged:

```yaml
externalSecrets:
  target:
    template:
      data:
        token: '{{ `{{ .token }}` }}'
```

This renders the final value as `{{ .token }}` for External Secrets Operator to
evaluate.
