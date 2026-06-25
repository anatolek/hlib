# hlib

![Version: 0.8.0](https://img.shields.io/badge/Version-0.8.0-informational?style=flat-square) ![Type: library](https://img.shields.io/badge/Type-library-informational?style=flat-square)
[![GitHub license](https://img.shields.io/github/license/anatolek/helm-charts)](https://github.com/anatolek/helm-charts)

A reusable Helm library chart that provides common Kubernetes template primitives for building consistent, maintainable charts across applications.
This library eliminates code duplication by offering pre-built templates for standard Kubernetes resources including deployments, services, ingress, RBAC, jobs, and more.
Charts using this library benefit from standardized configurations, unified resource tiers, and consistent labeling patterns.

## Requirements

Kubernetes: `>=1.32.0-0`

The library may include new resource parameters that are recently added, enabled by default, and marked as at least a beta feature.
Also, some old parameters and API versions may be deprecated and their support removed from the library.

## Predefined variables

These are auxiliary variables/configurations defined in the library that can be reused wherever needed.

| Dependency                 | Description                                                                                                                                                                                                                                                                    |
|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `hlib.name`           | Takes the next value in order, depending on whether override value is specified `{{ .Chart.Name }}` -> `{{ .Values.nameOverride }}`.                                                                                                                                           |
| `hlib.fullname`       | Takes the next value in order, depending on whether override values are specified `{{ .Release.Name }}-{{ .Chart.Name }}` -> `{{ .Values.nameOverride }}` (if includes .Release.Name) -> `{{ .Release.Name }}-{{ .Values.nameOverride }}` -> `{{ .Values.fullnameOverride }}`. |
| `hlib.chart`          | Takes the next value  `{{ .Chart.Name }}-{{ .Chart.Version }}`.                                                                                                                                                                                                                |
| `hlib.selectorLabels` | Renders the following labels: `app.kubernetes.io/name`, `app.kubernetes.io/instance`.                                                                                                                                                                                          |
| `hlib.labels`         | Renders the following labels: all labels that `hlib.selectorLabels` has, `helm.sh/chart`, `app.kubernetes.io/version`, `app.kubernetes.io/part-of`, `app.kubernetes.io/managed-by`.                                                                                       |

## Predefined functions

These are auxiliary functions defined in the library that can be reused wherever needed.

### `hlib.util.merge`

Merges two YAML snippets rendered by template includes.

**Inputs:**

- `.override` (string): Name of the override template to include and parse.
- `.base` (string): Name of the base template to include and parse.
- `.context` (dict): Values context for evaluating `.override`.

The override values take precedence over the base.

**Usage:**

```handlebars
{{ include "hlib.util.merge" (dict "override" "template.override" "base" "template.base" "context" .) }}
```

### `hlib.util.renderEnvVars`

Renders Kubernetes environment variable definitions based on input dictionary.

**Inputs:**

- `.env` (dict): A map of environment variable keys to values or configuration objects.
- `.context` (dict): Optional context for evaluating values.

**Supported value formats:**

- List-formatted values ("slice") rendered as is.

  Example:

  ```yaml
  - name: FOO
    value: bar
  ```

  Result:

  ```yaml
  - name: "FOO"
    value: "bar"
  ```

- Simple values (string, int, float, bool) rendered as plain `value: "<string>"`.

  Example:
  ```yaml
  FOO: "bar"
  ```

  Result:

  ```yaml
  - name: "FOO"
    value: "bar"
  ```

- Secret references.

  Example:

  ```yaml
  SECRET:
    secretKeyRef:
      my-secret: password
  ```

  Result:

  ```yaml
  - name: "SECRET"
    valueFrom:
      secretKeyRef:
        name: "my-secret"
        key: "password"
  ```

- ConfigMap references.

  Example:

  ```yaml
  CONFIG:
    configMapKeyRef:
      my-config: setting
  ```

  Result:

  ```yaml
  - name: "CONFIG"
    valueFrom:
      configMapKeyRef:
        name: "my-config"
        key: "setting"
  ```

- Downward API field references.

  Example:

  ```yaml
  POD_NAME:
    fieldRef: metadata.name
  ```

  Result:

  ```yaml
  - name: "POD_NAME"
    valueFrom:
      fieldRef:
        fieldPath: "metadata.name"
  ```

- Downward API resource field references.

  Example:

  ```yaml
  CPU_REQUEST:
    resourceFieldRef:
      resource: requests.cpu
      containerName: app
      divisor: "1m"
  ```

  Result:

  ```yaml
  - name: "CPU_REQUEST"
    valueFrom:
      resourceFieldRef:
        resource: "requests.cpu"
        containerName: "app"
        divisor: "1m"
  ```

**Ignored:**

Entries with a value of `<no value>` or empty/null will be skipped.

**Usage:**

```handlebars
{{ include "hlib.util.renderEnvVars" (dict "env" .Values.env "context" .) }}
```

### `hlib.util.image`

Renders a full image reference string using registry, repository, tag, or digest.

**Inputs:**

- `.imageRoot.repository` (string): Required. The image repository (e.g., "nginx").
- `.imageRoot.tag` (string, optional): The image tag (e.g., "1.23.4"). Falls back to .chart.AppVersion if not set.
- `.imageRoot.digest` (string, optional): The image digest (e.g., "sha256:abcd1234"). Overrides tag if set.
- `.imageRoot.registry` (string, optional): The image registry (e.g., "ghcr.io/myorg"). Can also be overridden globally.
- `.global.imageRegistry` (string, optional): Fallback registry if .imageRoot.registry is not set.
- `.chart.AppVersion` (string, optional): Used as fallback tag if neither tag nor digest is provided.

**Behavior:**

- Uses "@" as separator if digest is provided, ":" otherwise.
- If both registry and digest are set, e.g. `ghcr.io/myorg/app@sha256:abc123`
- If tag is missing and digest is not provided, defaults to chart AppVersion.

**Examples:**

Input:

```yaml
imageRoot:
  repository: myapp
  tag: "2.0.1"
  registry: "ghcr.io/myteam"
```

Output:

```yaml
ghcr.io/myteam/myapp:2.0.1
```

**Usage:**

```handlebars
{{ include "hlib.util.image" (dict "imageRoot" .Values.path.to.the.image "global" .Values.global "chart" .Chart) }}
```

### `hlib.util.tplrender`

This template evaluates a string or YAML object as a Helm template using the `tpl` function.

**Inputs:**

- `value` (any): The string or YAML structure to render (can contain Go template expressions like {{ .Values.* }}).
- `context` (dict): The context (usually `.`) for evaluating templates.
- `scope` (dict): (optional) The scope to be used inside a `with` block for relative references.

**Behavior:**

- If `value` is a plain string, it is evaluated with `tpl`.
- If `value` is a YAML map or list, it is first serialized to YAML or JSON.
- If the rendered content contains `{{`, `tpl` is used to evaluate it.
- If `scope` is provided, it wraps the template in a `with` block using `RelativeScope`.
  Use `scope` when the template string references variables not in the top-level context (like .Values.*),
  but in local or nested structures like iteration items, condition blocks, or subfields.

**Examples:**

1. Rendering a plain templated string:
   ```handlebars
   {{ include "hlib.util.tplrender" (dict "value" .Values.path.to.the.Value "context" $) }}
   ```

2. Rendering YAML with templates and a scope:
   ```handlebars
   {{ include "hlib.util.tplrender" (dict "value" .Values.path.to.the.Value "context" $ "scope" $app) }}
   ```

**Output:**

The resulting evaluated template as a string or YAML structure.

### `hlib.util.springKafkaValues`

This template renders prefixed Kafka values either as:

1. A single value.

   Example:

   ```handlebars
   {{ include "hlib.util.springKafkaValues" (dict "prefix" "spring.kafka.listener.concurrency" "values" "3") }}
   ```

   Output:

   ```yaml
   "spring.kafka.listener.concurrency": "3"
   ```

2. A list of key=value pairs separated by semicolons.

   Example:

   ```handlebars
   {{ include "hlib.util.springKafkaValues" (dict "prefix" "spring.kafka" "values" "listener.concurrency=3;consumer.auto-offset-reset=earliest") }}
   ```

   Output:

   ```yaml
   "spring.kafka.listener.concurrency": "3"
   "spring.kafka.consumer.auto-offset-reset": "earliest"
   ```

### `hlib.default-check-required-msg`

A default message string to be used when checking for a required value

**Usage:**

```handlebars
{{- $requiredMsg := include "hlib.default-check-required-msg" $ -}}
{{ required (printf $requiredMsg "SOME.VALUE.NAME") .Values.some.value }}
```

## Using the Helm library

### `hlib.container` template

Creates Kubernetes container specification.

#### Basic Usage

Include within your controller template (e.g., deployment):

```handlebars
containers:
- {{- include "hlib.container" (dict "context" . "values" .Values.container) }}
```

Add the following values

```yaml
container:
  # resourceTier: "m250Mi-c250m"
  image:
    repository: busybox
```

#### Configuration

| Parameter      | Description                                                               | Required | Default                        |
|----------------|---------------------------------------------------------------------------|----------|--------------------------------|
| `context`      | Root Helm context (usually `.`)                                           | Yes      | -                              |
| `values`       | Container configuration values (from `values.yaml`)                       | No       | `.Values.deployment.container` |
| `env`          | Environment variables to add to the container                             | No       | -                              |
| `override`     | Name of a template that overrides the basic one configured in the library | No       | -                              |

**Environment Variables**

You can assign container values to `env` parameter directly, e.g.

```handlebars
containers:
- {{- include "hlib.container" (dict "context" . "env" (fromYaml "FOO: true\nBAR: OK")) }}
```

or as a rendered template

```handlebars
...
{{- $env := fromYaml (include "container.env" .) -}}
spec:
  template:
    spec:
      containers:
      - {{- include "hlib.container" (dict "context" . "env" $env) }}
...

{{- define "container.env" -}}
FOO: true
BAR: OK
{{- end -}}
```

Combine pre-rendered `env` + `extraEnv`:

```yaml
container:
  extraEnv:
    LOG_LEVEL: debug
```

**Resource tier (`resourceTier`)**

You can set a compact string instead of spelling out `container.resources`. The format is **`m<memory>-c<cpu>`** where the leading `m` / `c` letters are case-insensitive. Memory and CPU values must be valid Kubernetes quantities (same as in a Pod spec).

Examples:

```yaml
container:
  resourceTier: "m100Mi-c100m"
```

```yaml
container:
  resourceTier: "M100M-C1"
```

Rendered resources:

- **Requests:** `memory` and `cpu` from the string; `ephemeral-storage` is always `50Mi`.
- **Limits:** `memory` matches requests; `ephemeral-storage` is always `2Gi`. **CPU is not set in limits** (only in requests).

**Precedence:** If `container.resources.requests` is set, that block is used and `resourceTier` is ignored. Use either full `container.resources` or `resourceTier`, or set resources when you need to override a tier for a specific environment.

**Temporary `/tmp` volume (`tmpDir`)**

By default, controllers inject an `emptyDir` volume named `temp-dir` and mount it at `/tmp` in the container. Configure or disable it via `container.tmpDir`:

```yaml
container:
  tmpDir:
    enabled: true
    mountPath: /tmp
    medium: ""        # e.g. "Memory" for tmpfs
    sizeLimit: ""     # e.g. "64Mi"
```

Set `enabled: false` when the container does not need a writable `/tmp` volume. Set `medium: Memory` and `sizeLimit` when you need a bounded tmpfs.

#### Advanced: Template Overrides

The changes can only be added to the container base template via `override` parameter.
For example, if it is needed to add a secret resource as input variables for container:

```handlebars
{{- include "hlib.deployment" (dict "context" . "override" "app.deployment") -}}

{{- define "app.deployment" -}}
spec:
  template:
    metadata:
      annotations:
        checksum/secret: {{ include (print .Template.BasePath "/secret.yaml") $ | sha256sum }}
    spec:
      containers:
      - {{- include "hlib.container" (dict "context" . "override" "app.deployment.container") }}
{{- end -}}

{{- define "app.deployment.container" -}}
envFrom:
  - secretRef:
      name: {{ include "hlib.fullname" . }}
{{- end -}}
```

### `hlib.deployment` template

Creates Kubernetes Deployment manifest.
By default, only one container is deployed due to the complexity of implementing multi-containerization.

#### Basic Usage

Include this template in your chart's `templates/deployment.yaml`:

```handlebars
{{- include "hlib.deployment" (dict "context" . "values" .Values.deployment) }}
```

Add the following values

```yaml
deployment:
  container:
    # resourceTier: "m100Mi-c100m"
    port: 8080
    image:
      repository: nginx
```

#### Configuration

| Parameter      | Description                                                               | Required | Default              |
|----------------|---------------------------------------------------------------------------|----------|----------------------|
| `context`      | Root Helm context (usually `.`)                                           | Yes      | -                    |
| `values`       | Deployment configuration values (from `values.yaml`)                      | No       | `.Values.deployment` |
| `envTpl`       | Name of a template that generates environment variables in YAML format    | No       | -                    |
| `dependencies` | Dictionary of dependent components (see below)                            | No       | -                    |
| `override`     | Name of a template that overrides the basic one configured in the library | No       | -                    |

**Dependency Integration**

Used to override the configuration path of resources on which it depends.

| Dependency       | Usage                                                | Default                  |
|------------------|------------------------------------------------------|--------------------------|
| `autoscaling`    | Auto-scaling status (disables replicas when enabled) | `.Values.autoscaling`    |
| `serviceAccount` | Service account name injection                       | `.Values.serviceAccount` |

```handlebars
{{- $dependencies := dict "autoscaling" .Values.newAutoscaling "serviceAccount" .Values.newServiceAccount -}}
{{- include "hlib.deployment" (dict "context" . "dependencies" $dependencies) }}
```

**Environment Variables**

Provide a template name to `envTpl` that outputs environment variables in valid YAML format:

```handlebars
{{- include "hlib.deployment" (dict "context" . "envTpl" "your.env.template") }}
```

Example template (`templates/_env.yaml`):
```handlebars
{{- define "your.env.template" -}}
- name: ENV_VAR
  value: "production"
{{- end -}}

# or use a simplified approach

{{- define "your.env.template" -}}
ENV_VAR: "production"
{{- end -}}
```

#### Advanced: Template Overrides

If there is no need to make any changes to the container,
the changes can only be added to the deployment base template via `override` parameter as follows:

```handlebars
{{- include "hlib.deployment" (dict "context" . "override" "app.deployment" "envTpl" "app.deployment.container.env") -}}

{{- define "app.deployment" -}}
spec:
  template:
    metadata:
      annotations:
        checksum/secret: {{ include (print .Template.BasePath "/secret.yaml") $ | sha256sum }}
{{- end -}}

{{- define "app.deployment.container.env" -}}
TZ: {{ ((.Values.global).timezone) }}
PASSWORD:
  secretKeyRef:
    {{ include "hlib.fullname" . }}: PASSWORD
{{- end -}}
```

### `hlib.daemonSet` template

Creates Kubernetes DaemonSet manifest.
By default, only one container is deployed due to the complexity of implementing multi-containerization.

#### Basic Usage

Include this template in your chart's `templates/daemonset.yaml`:

```handlebars
{{- include "hlib.daemonSet" (dict "context" . "values" .Values.daemonset) }}
```

Add the following values

```yaml
daemonset:
  container:
    # resourceTier: "m100Mi-c100m"
    image:
      repository: busybox
```

#### Configuration

| Parameter      | Description                                                               | Required | Default              |
|----------------|---------------------------------------------------------------------------|----------|----------------------|
| `context`      | Root Helm context (usually `.`)                                           | Yes      | -                    |
| `values`       | DaemonSet configuration values (from `values.yaml`)                       | No       | `.Values.daemonset`  |
| `envTpl`       | Name of a template that generates environment variables in YAML format    | No       | -                    |
| `dependencies` | Dictionary of dependent components (see below)                            | No       | -                    |
| `override`     | Name of a template that overrides the basic one configured in the library | No       | -                    |

**Dependency Integration**

Used to override the configuration path of resources on which it depends.

| Dependency       | Usage                          | Default                  |
|------------------|--------------------------------|--------------------------|
| `serviceAccount` | Service account name injection | `.Values.serviceAccount` |

```handlebars
{{- $dependencies := dict "serviceAccount" .Values.newServiceAccount -}}
{{- include "hlib.daemonSet" (dict "context" . "dependencies" $dependencies) }}
```

**Environment Variables**

Provide a template name to `envTpl` that outputs environment variables in valid YAML format:

```handlebars
{{- include "hlib.daemonSet" (dict "context" . "envTpl" "your.env.template") }}
```

Example template (`templates/_env.yaml`):
```handlebars
{{- define "your.env.template" -}}
- name: ENV_VAR
  value: "production"
{{- end -}}

# or use a simplified approach

{{- define "your.env.template" -}}
ENV_VAR: "production"
{{- end -}}
```

#### Advanced: Template Overrides

If there is no need to make any changes to the container,
the changes can only be added to the DaemonSet base template via `override` parameter as follows:

```handlebars
{{- include "hlib.daemonSet" (dict "context" . "override" "app.daemonSet" "envTpl" "app.daemonSet.container.env") -}}

{{- define "app.daemonSet" -}}
spec:
  template:
    metadata:
      annotations:
        checksum/secret: {{ include (print .Template.BasePath "/secret.yaml") $ | sha256sum }}
{{- end -}}

{{- define "app.daemonSet.container.env" -}}
TZ: {{ ((.Values.global).timezone) }}
PASSWORD:
  secretKeyRef:
    {{ include "hlib.fullname" . }}: PASSWORD
{{- end -}}
```

### `hlib.cronJob` template

Creates Kubernetes CronJob manifest.
By default, only one container is deployed due to the complexity of implementing multi-containerization.

#### Basic Usage

Include this template in your chart's `templates/cron-job.yaml`:

```handlebars
{{- include "hlib.cronJob" (dict "context" . "values" .Values.cronJob) }}
```

Add the following values

```yaml
cronJob:
  schedule: "* * * * *"
  container:
    # resourceTier: "m100Mi-c100m"
    image:
      repository: busybox
```

#### Configuration

The basic template is created with some predefined non-default parameters:

```yaml
spec:
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
```

| Parameter      | Description                                                               | Required | Default           |
|----------------|---------------------------------------------------------------------------|----------|-------------------|
| `context`      | Root Helm context (usually `.`)                                           | Yes      | -                 |
| `values`       | CronJob configuration values (from `values.yaml`)                         | No       | `.Values.cronJob` |
| `envTpl`       | Name of a template that generates environment variables in YAML format    | No       | -                 |
| `dependencies` | Dictionary of dependent components (see below)                            | No       | -                 |
| `override`     | Name of a template that overrides the basic one configured in the library | No       | -                 |

**Dependency Integration**

Used to override the configuration path of resources on which it depends.

| Dependency       | Usage                                                | Default                  |
|------------------|------------------------------------------------------|--------------------------|
| `serviceAccount` | Service account name injection                       | `.Values.serviceAccount` |

```handlebars
{{- $dependencies := dict "serviceAccount" .Values.newServiceAccount -}}
{{- include "hlib.cronJob" (dict "context" . "dependencies" $dependencies) }}
```

**Environment Variables**

Provide a template name to `envTpl` that outputs environment variables in valid YAML format:

```handlebars
{{- include "hlib.cronJob" (dict "context" . "envTpl" "your.env.template") }}
```

Example template (`templates/_env.yaml`):
```handlebars
{{- define "your.env.template" -}}
- name: ENV_VAR
  value: "production"
{{- end -}}

# or use a simplified approach

{{- define "your.env.template" -}}
ENV_VAR: "production"
{{- end -}}
```

#### Advanced: Template Overrides

If there is no need to make any changes to the container,
the changes can only be added to the CronJob base template via `override` parameter as follows:

```handlebars
{{- include "hlib.cronJob" (dict "context" . "override" "app.cronJob" "envTpl" "app.cronJob.container.env") -}}

{{- define "app.cronJob" -}}
spec:
  template:
    metadata:
      annotations:
        cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
{{- end -}}

{{- define "app.cronJob.container.env" -}}
TZ: {{ ((.Values.global).timezone) }}
PASSWORD:
  secretKeyRef:
    {{ include "hlib.fullname" . }}: PASSWORD
{{- end -}}
```

### `hlib.job` template

Creates Kubernetes Job manifest.
By default, only one container is deployed due to the complexity of implementing multi-containerization.

#### Basic Usage

Include this template in your chart's `templates/job.yaml`:

```handlebars
{{- include "hlib.job" (dict "context" . "values" .Values.job) }}
```

Add the following values

```yaml
job:
  container:
    # resourceTier: "m100Mi-c100m"
    port: 8080
    image:
      repository: nginx
```

#### Configuration

The basic template is created with some predefined non-default parameters:

```yaml
spec:
  # It is recommended to use this parameter for one-time jobs instead of a Helm hook
  # that deletes the job immediately --> "helm.sh/hook-delete-policy": hook-succeeded
  ttlSecondsAfterFinished: 3600  # Completed job will be deleted after 1 hour.
  template:
    spec:
      restartPolicy: Never
```

| Parameter      | Description                                                               | Required | Default       |
|----------------|---------------------------------------------------------------------------|----------|---------------|
| `context`      | Root Helm context (usually `.`)                                           | Yes      | -             |
| `values`       | Job configuration values (from `values.yaml`)                             | No       | `.Values.job` |
| `envTpl`       | Name of a template that generates environment variables in YAML format    | No       | -             |
| `dependencies` | Dictionary of dependent components (see below)                            | No       | -             |
| `override`     | Name of a template that overrides the basic one configured in the library | No       | -             |

**Dependency Integration**

Used to override the configuration path of resources on which it depends.

| Dependency       | Usage                                                | Default                  |
|------------------|------------------------------------------------------|--------------------------|
| `serviceAccount` | Service account name injection                       | `.Values.serviceAccount` |

```handlebars
{{- $dependencies := dict "serviceAccount" .Values.newServiceAccount -}}
{{- include "hlib.job" (dict "context" . "dependencies" $dependencies) }}
```

**Environment Variables**

Provide a template name to `envTpl` that outputs environment variables in valid YAML format:

```handlebars
{{- include "hlib.job" (dict "context" . "envTpl" "your.env.template") }}
```

Example template (`templates/_env.yaml`):
```handlebars
{{- define "your.env.template" -}}
- name: ENV_VAR
  value: "production"
{{- end -}}

# or use a simplified approach

{{- define "your.env.template" -}}
ENV_VAR: "production"
{{- end -}}
```

#### Advanced: Template Overrides

If there is no need to make any changes to the container,
the changes can only be added to the job base template via `override` parameter as follows:

```handlebars
{{- include "hlib.job" (dict "context" . "override" "app.job" "envTpl" "app.job.container.env") -}}

{{- define "app.job" -}}
metadata:
  name: {{ printf "%s-pre-deploy" (include "hlib.fullname" $) | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{- define "app.job.container.env" -}}
TZ: {{ ((.Values.global).timezone) }}
{{- end -}}
```

### `hlib.service` template

Creates Kubernetes Service resources.

By default, a service with type `ClusterIP` is created on port 80.

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

### `hlib.serviceAccount` template

Creates Kubernetes ServiceAccount resources.

> It is considered good practice to use non-default service accounts for all applications.
> If the application does not need to communicate with the Kubernetes API,
> then from a security point of view it is better to set the `automountServiceAccountToken` parameter to `false`.

#### Basic Usage

Include this template in your chart's `templates/serviceaccount.yaml`:

```handlebars
{{- include "hlib.serviceAccount" (dict "context" .) }}
```

#### Configuration

| Parameter  | Description                                                               | Required | Default                  |
|------------|---------------------------------------------------------------------------|----------|--------------------------|
| `context`  | Root Helm context (usually `.`)                                           | Yes      | -                        |
| `values`   | Service Account configuration values (from `values.yaml`)                 | No       | `.Values.serviceAccount` |
| `override` | Name of a template that overrides the basic one configured in the library | No       | -                        |

#### Advanced: Template Overrides

The changes can only be added to the base template via `override` parameter, e.g.:

```handlebars
{{- include "hlib.serviceAccount" (dict "context" . "override" "app.sa") -}}

{{- define "app.sa" -}}
imagePullSecrets:
  - name: docker.tract-eng.com
{{- end -}}
```

### `hlib.secret` template

Creates Kubernetes Secret resources.

It has several pre-defined annotations.

```yaml
annotations:
  "helm.sh/hook": pre-install,pre-upgrade
  "helm.sh/hook-weight": "1"
```

#### Basic Usage

Include this template in your chart's `templates/secret.yaml`:

```handlebars
{{- include "hlib.secret" (dict "context" .) }}
```

#### Configuration

| Parameter  | Description                                                               | Required | Default          |
|------------|---------------------------------------------------------------------------|----------|------------------|
| `context`  | Root Helm context (usually `.`)                                           | Yes      | -                |
| `values`   | Secret configuration values (from `values.yaml`)                          | No       | `.Values.secret` |
| `override` | Name of a template that overrides the basic one configured in the library | No       | -                |

#### Advanced: Template Overrides

The changes can only be added to the base template via `override` parameter, e.g.:

```handlebars
{{- include "hlib.secret" (dict "context" . "override" "app.secret") -}}

{{- define "app.secret" -}}
data:
  PASSWORD: "P@ssvv0rd"
{{- end -}}
```

### `hlib.configMap` template

Creates Kubernetes ConfigMap resources.

It has several pre-defined annotations.

```yaml
annotations:
  "helm.sh/hook": pre-install,pre-upgrade
  "helm.sh/hook-weight": "1"
```

#### Basic Usage

Include this template in your chart's `templates/configmap.yaml`:

```handlebars
{{- include "hlib.configMap" (dict "context" .) }}
```

#### Configuration

| Parameter  | Description                                                               | Required | Default             |
|------------|---------------------------------------------------------------------------|----------|---------------------|
| `context`  | Root Helm context (usually `.`)                                           | Yes      | -                   |
| `values`   | ConfigMap configuration values (from `values.yaml`)                       | No       | `.Values.configMap` |
| `override` | Name of a template that overrides the basic one configured in the library | No       | -                   |

#### Advanced: Template Overrides

The changes can only be added to the base template via `override` parameter, e.g.:

```handlebars
{{- include "hlib.configMap" (dict "context" . "override" "app.configMap") -}}

{{- define "app.configMap" -}}
data:
  server.conf: |
    port 1194
    proto udp
    dev tun
    ca ca.crt
    cert server.crt
    key server.key
    dh dh2048.pem
    server 10.8.0.0 255.255.255.0
{{- end -}}
```

### `hlib.ingress` template

Creates Kubernetes Ingress manifest.

#### Basic Usage

Include this template in your chart's `templates/ingress.yaml`:

```handlebars
{{- include "hlib.ingress" (dict "context" .) }}
```

Add the following values

```yaml
ingress:
  className: nginx-internal  # Controller-specific
  tls:
    - hosts:
        - app.example.com
      secretName: tls-cert  # Must exist in namespace
  hosts:
    - host: app.example.com
      paths:
        - path: /api
          pathType: Prefix
        - path: /static
          pathType: Exact
```

#### Configuration

| Parameter      | Description                                                               | Required | Default           |
|----------------|---------------------------------------------------------------------------|----------|-------------------|
| `context`      | Root Helm context (usually `.`)                                           | Yes      | -                 |
| `values`       | Ingress configuration values (from `values.yaml`)                         | No       | `.Values.ingress` |
| `dependencies` | Dictionary of dependent components (see below)                            | No       | -                 |
| `override`     | Name of a template that overrides the basic one configured in the library | No       | -                 |

**Dependency Integration**

Used to override the configuration path of resources on which it depends.

| Dependency | Usage                  | Default           |
|------------|------------------------|-------------------|
| `service`  | Service name injection | `.Values.service` |

```handlebars
{{- $dependencies := dict "service" .Values.newService -}}
{{- include "hlib.ingress" (dict "context" . "dependencies" $dependencies) }}
```

#### Advanced: Template Overrides

If there is no need to make any changes to the container,
the changes can only be added to the ingress base template via `override` parameter as follows:

```handlebars
{{- include "hlib.ingress" (dict "context" . "override" "app.ingress") -}}

{{- define "app.ingress" -}}
metadata:
  name: {{ printf "%s-ui" (include "hlib.fullname" $) | trunc 63 | trimSuffix "-" }}
{{- end -}}
```

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
  scheme: https
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

Rules without a `backendRefs` key automatically route traffic to the chart's Service. To create a rule that does not forward traffic, such as a redirect-only rule, explicitly set `backendRefs: []`:

```yaml
httpRoute:
  rules:
    - filters:
        - type: RequestRedirect
          requestRedirect:
            scheme: https
            statusCode: 301
      backendRefs: []
```

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

### `hlib.networkPolicy` template

Creates Kubernetes NetworkPolicy resources.

By default, the policy applies to the pods selected by the chart's selector labels. No
`ingress`, `egress`, or `policyTypes` fields are rendered unless explicitly provided.

NetworkPolicy rules are allowlists. For example, setting `policyTypes: [Ingress]` with
no ingress rules denies all ingress traffic to the selected pods.

#### Basic Usage

Include this template in your chart's `templates/network-policy.yaml`:

```handlebars
{{- include "hlib.networkPolicy" (dict "context" .) }}
```

#### Configuration

| Parameter  | Description                                                               | Required | Default                 |
|------------|---------------------------------------------------------------------------|----------|-------------------------|
| `context`  | Root Helm context (usually `.`)                                           | Yes      | -                       |
| `values`   | NetworkPolicy configuration values (from `values.yaml`)                   | No       | `.Values.networkPolicy` |
| `override` | Name of a template that overrides the basic one configured in the library | No       | -                       |

**Configure ingress and egress rules**

Rules are defined via `networkPolicy.ingress` and `networkPolicy.egress`, mirroring the Kubernetes API. Set `networkPolicy.policyTypes` to control which rule types apply:

```yaml
networkPolicy:
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: frontend
      ports:
        - protocol: TCP
          port: 80
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.0.0/24
      ports:
        - protocol: TCP
          port: 5978
```

**Override the selected pods**

By default, `podSelector` matches the chart's selector labels. Provide
`networkPolicy.podSelector` to target different pods:

```yaml
networkPolicy:
  podSelector:
    matchLabels:
      app.kubernetes.io/component: api
```

Set an empty selector to select all pods in the namespace, for example for a
default-deny ingress policy:

```yaml
networkPolicy:
  podSelector: {}
  policyTypes:
    - Ingress
  ingress: []
```

#### Advanced: Template Overrides

Additional fields can be merged into the base template with the `override` parameter:

```handlebars
{{- include "hlib.networkPolicy" (dict "context" . "override" "app.networkPolicy") -}}

{{- define "app.networkPolicy" -}}
metadata:
  labels:
    network-policy-purpose: restricted
{{- end -}}
```

### `hlib.hpa` template

Creates Kubernetes HorizontalPodAutoscaler resources.

#### Basic Usage

Include this template in your chart's `templates/hpa.yaml`:

```handlebars
{{- include "hlib.hpa" (dict "context" .) }}
```

#### Configuration

| Parameter      | Description                                                               | Required | Default               |
|----------------|---------------------------------------------------------------------------|----------|-----------------------|
| `context`      | Root Helm context (usually `.`)                                           | Yes      | -                     |
| `values`       | Autoscaling configuration values (from `values.yaml`)                     | No       | `.Values.autoscaling` |
| `dependencies` | Dictionary of dependent components (see below)                            | No       | -                     |
| `override`     | Name of a template that overrides the basic one configured in the library | No       | -                     |

**Dependency Integration**

Used to override the configuration path of resources on which it depends.

| Dependency   | Usage                | Default              |
|--------------|----------------------|----------------------|
| `deployment` | Deploymnet reference | `.Values.deployment` |

```handlebars
{{- $dependencies := dict "deployment" .Values.newDeployment -}}
{{- include "hlib.hpa" (dict "context" . "dependencies" $dependencies) }}
```

#### Advanced: Template Overrides

The changes can only be added to the base template via `override` parameter, e.g.:

```handlebars
{{- include "hlib.hpa" (dict "context" . "override" "app.hpa") -}}

{{- define "app.hpa" -}}
apiVersion: autoscaling/v1
{{- end -}}
```

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

### `hlib.pdb` template

Creates Kubernetes PodDisruptionBudget resources.

By default, it is established that only `1` pod may be unavailable after the eviction starts.

#### Basic Usage

Include this template in your chart's `templates/pdb.yaml`:

```handlebars
{{- include "hlib.pdb" (dict "context" .) }}
```

#### Configuration

| Parameter      | Description                                                               | Required | Default       |
|----------------|---------------------------------------------------------------------------|----------|---------------|
| `context`      | Root Helm context (usually `.`)                                           | Yes      | -             |
| `values`       | Pod Disruption Budget configuration values (from `values.yaml`)           | No       | `.Values.pdb` |
| `override`     | Name of a template that overrides the basic one configured in the library | No       | -             |

#### Advanced: Template Overrides

The changes can only be added to the base template via `override` parameter, e.g.:

```handlebars
{{- include "hlib.pdb" (dict "context" . "override" "app.pdb") -}}

{{- define "app.pdb" -}}
spec:
  selector:
    matchExpressions:
      - { key: environment, operator: In, values: [dev] }
{{- end -}}
```

### `hlib.role` template

Creates Kubernetes Role resources.

#### Basic Usage

Include this template in your chart's `templates/role.yaml`:

```handlebars
{{- include "hlib.role" (dict "context" .) }}
```

#### Configuration

| Parameter  | Description                                                               | Required | Default             |
|------------|---------------------------------------------------------------------------|----------|---------------------|
| `context`  | Root Helm context (usually `.`)                                           | Yes      | -                   |
| `values`   | Role configuration values (from `values.yaml`)                            | No       | `.Values.rbac.role` |
| `override` | Name of a template that overrides the basic one configured in the library | No       | -                   |

#### Advanced: Template Overrides

The changes can only be added to the base template via `override` parameter, e.g.:

```handlebars
{{- include "hlib.role" (dict "context" . "override" "app.role") -}}

{{- define "app.role" -}}
rules:
  - apiGroups: [""]
    resources: ["configmaps", "pods"]
    verbs: ["get", "list"]
{{- end -}}
```

### `hlib.roleBinding` template

Creates Kubernetes roleBinding resources.
By default, only one binding is created per service account.

#### Basic Usage

Include this template in your chart's `templates/role-binding.yaml`:

```handlebars
{{- include "hlib.roleBinding" (dict "context" .) }}
```

#### Configuration

| Parameter      | Description                                                               | Required | Default                    |
|----------------|---------------------------------------------------------------------------|----------|----------------------------|
| `context`      | Root Helm context (usually `.`)                                           | Yes      | -                          |
| `values`       | roleBinding configuration values (from `values.yaml`)                     | No       | `.Values.rbac.roleBinding` |
| `dependencies` | Dictionary of dependent components (see below)                            | No       | -                          |
| `override`     | Name of a template that overrides the basic one configured in the library | No       | -                          |

**Dependency Integration**

Used to override the configuration path of resources on which it depends.

| Dependency       | Usage                     | Default                  |
|------------------|---------------------------|--------------------------|
| `role`           | Role reference            | `.Values.rbac.role`      |
| `serviceAccount` | Service account reference | `.Values.serviceAccount` |

```handlebars
{{- $dependencies := dict "role" .Values.newRole "serviceAccount" .Values.newServiceAccount -}}
{{- include "hlib.deployment" (dict "context" . "dependencies" $dependencies) }}
```

#### Advanced: Template Overrides

The changes can only be added to the base template via `override` parameter, e.g.:

```handlebars
{{- include "hlib.roleBinding" (dict "context" . "override" "app.roleBinding") -}}

{{- define "app.roleBinding" -}}
metadata:
  name: {{ printf "%s-rb" (include "hlib.name" $) | trunc 63 | trimSuffix "-" }}
{{- end -}}
```

### `hlib.clusterRole` template

Creates Kubernetes ClusterRole resources.

#### Basic Usage

Include this template in your chart's `templates/cluster-role.yaml`:

```handlebars
{{- include "hlib.clusterRole" (dict "context" .) }}
```

#### Configuration

| Parameter      | Description                                                               | Required | Default                    |
|----------------|---------------------------------------------------------------------------|----------|----------------------------|
| `context`      | Root Helm context (usually `.`)                                           | Yes      | -                          |
| `values`       | ClusterRole configuration values (from `values.yaml`)                     | No       | `.Values.rbac.clusterRole` |
| `override`     | Name of a template that overrides the basic one configured in the library | No       | -                          |

**Role Aggregation**

Combine existing ClusterRoles using label selectors, e.g.

```yaml
rbac:
  clusterRole:
    aggregationClusterRoleSelectors:
      - matchLabels:
          rbac.group/type: "monitoring"
```

#### Advanced: Template Overrides

The changes can only be added to the base template via `override` parameter, e.g.:

```handlebars
{{- include "hlib.clusterRole" (dict "context" . "override" "app.clusterRole") -}}

{{- define "app.clusterRole" -}}
rules:
  - apiGroups: [""]
    resources: ["endpoints", "pods", "nodes", "services"]
    verbs: ["get", "list"]
{{- end -}}
```

### `hlib.clusterRoleBinding` template

Creates Kubernetes ClusterRoleBinding resources.
By default, only one binding is created per service account.

#### Basic Usage

Include this template in your chart's `templates/cluster-role-binding.yaml`:

```handlebars
{{- include "hlib.clusterRoleBinding" (dict "context" .) }}
```

#### Configuration

| Parameter      | Description                                                               | Required | Default                           |
|----------------|---------------------------------------------------------------------------|----------|-----------------------------------|
| `context`      | Root Helm context (usually `.`)                                           | Yes      | -                                 |
| `values`       | ClusterRoleBinding configuration values (from `values.yaml`)              | No       | `.Values.rbac.clusterRoleBinding` |
| `dependencies` | Dictionary of dependent components (see below)                            | No       | -                                 |
| `override`     | Name of a template that overrides the basic one configured in the library | No       | -                                 |

**Dependency Integration**

Used to override the configuration path of resources on which it depends.

| Dependency       | Usage                     | Default                    |
|------------------|---------------------------|----------------------------|
| `clusterRole`    | Cluster role reference    | `.Values.rbac.clusterRole` |
| `serviceAccount` | Service account reference | `.Values.serviceAccount`   |

```handlebars
{{- $dependencies := dict "clusterRole" .Values.newClusterRole "serviceAccount" .Values.newServiceAccount -}}
{{- include "hlib.deployment" (dict "context" . "dependencies" $dependencies) }}
```

#### Advanced: Template Overrides

The changes can only be added to the base template via `override` parameter, e.g.:

```handlebars
{{- include "hlib.clusterRoleBinding" (dict "context" . "override" "app.clusterRoleBinding") -}}

{{- define "app.clusterRoleBinding" -}}
metadata:
  name: {{ printf "%s-rb" (include "hlib.name" $) | trunc 63 | trimSuffix "-" }}
{{- end -}}
```

### `hlib.diagnostic` template

Creates multiple Kubernetes resources that help developers provide extended access to the Kubernetes cluster for debugging.

#### Providing access

Generate a kubeconfig with admin access and send it to the engineer who needs this access

```shell
# Get current context
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}' | cut -d'/' -f2)
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
CLUSTER_NAMESPACE=<NAMESPACE_NAME>
TOKEN=$(kubectl get secret <SECRET_NAME> -o jsonpath='{.data.token}' | base64 -d)

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
    user: debug
    namespace: ${CLUSTER_NAMESPACE}
current-context: ${CLUSTER_NAME}-debug
users:
- name: debug
  user:
    token: ${TOKEN}
EOF
```

Kubeconfig usage

```shell
export KUBECONFIG=debug-kubeconfig.yaml
kubectl ...
```

> NOTE: This instruction may also appear when deploying an application with debug mode enabled.

#### Default access permissions

Namespace-scoped Role Permissions

| API Group    | Resources                                                  | Verbs         | Purpose                                      |
|--------------|------------------------------------------------------------|---------------|----------------------------------------------|
| `""`         | `pods`, `pods/log`                                         | `get`, `list` | View pod details and logs                    |
| `""`         | `pods/portforward`                                         | `create`      | Port-forward into pods                       |
| `""`         | `events`, `configmaps`                                     | `get`, `list` | View events and ConfigMaps                   |
| `apps`       | `replicasets`, `deployments`, `statefulsets`, `daemonsets` | `get`, `list` | Debug controllers managing workloads         |

Cluster-scoped ClusterRole Permissions

| API Group        | Resources                                                  | Verbs         | Purpose                                      |
|------------------|------------------------------------------------------------|---------------|----------------------------------------------|
| `""`             | `namespaces`                                               | `get`, `list` | Discover available namespaces                |
| `""`             | `nodes`, `persistentvolumes`                               | `get`, `list` | Understand node states and volume bindings   |
| `metrics.k8s.io` | `pods`                                                     | `get`, `list` | View pod-level resource usage metrics        |

Additional permissions can be configured using the following variables:

- `.Values.diagnosticMode.role.extraPermissionRules`
- `.Values.diagnosticMode.clusterRole.extraPermissionRules`

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

## Values

### Container

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| CONTROLLER.container.args | tpl/list | `[]` | Arguments to the command. |
| CONTROLLER.container.command | tpl/list | `[]` | Command array to run in the container. |
| CONTROLLER.container.extraEnv | tpl/list or tpl/object | [], {} | Additional environment variables to set in the container that can be represented in a list or dictionary format. |
| CONTROLLER.container.extraPorts | tpl/list | `[]` | Additional ports for the container. |
| CONTROLLER.container.image.digest | tpl/string | `""` | Container image digest that takes precedence over the tag. |
| CONTROLLER.container.image.registry | tpl/string | `.Values.global.imageRegistry` | Container image registry. |
| CONTROLLER.container.image.repository | tpl/string | `""` | Container image repository. |
| CONTROLLER.container.image.tag | tpl/string | `""` | Container image tag. |
| CONTROLLER.container.imagePullPolicy | tpl/string | `"Always"` | Image pull policy. |
| CONTROLLER.container.lifecycle | tpl/object | `{}` | Lifecycle hooks configuration. |
| CONTROLLER.container.livenessProbe | tpl/object | `{}` | Liveness probe configuration. |
| CONTROLLER.container.name | tpl/string | `"app"` | Container name override. |
| CONTROLLER.container.port | tpl/int | `nil` | Primary container port. |
| CONTROLLER.container.readinessProbe | tpl/object | `{}` | Readiness probe configuration. |
| CONTROLLER.container.resourceTier | tpl/string | `""` | Unified resource tier in format m<memory>-c<cpu> (e.g., m100Mi-c100m, M1Gi-C1). Used as a fallback when "container.resources" is not set. |
| CONTROLLER.container.resources.limits.cpu | tpl/string | `""` | CPU limit for the container (optional). |
| CONTROLLER.container.resources.limits.ephemeral-storage | tpl/string | `""` | Ephemeral storage limit for the container (optional). |
| CONTROLLER.container.resources.limits.memory | tpl/string | `""` | Memory limit for the container. |
| CONTROLLER.container.resources.requests.cpu | tpl/string | `""` | Requested CPU for the container. |
| CONTROLLER.container.resources.requests.ephemeral-storage | tpl/string | `""` | Requested ephemeral storage (optional). |
| CONTROLLER.container.resources.requests.memory | tpl/string | `""` | Requested memory for the container. |
| CONTROLLER.container.securityContext | tpl/object | `{}` | Container security context. |
| CONTROLLER.container.startupProbe | tpl/object | `{}` | Startup probe configuration. |
| CONTROLLER.container.terminationMessagePath | tpl/string | `""` | Path to the termination message file. |
| CONTROLLER.container.terminationMessagePolicy | tpl/string | `""` | Policy for termination message handling. |
| CONTROLLER.container.tmpDir.enabled | tpl/bool | `true` | Whether to mount a writable emptyDir volume at the container tmp path. |
| CONTROLLER.container.tmpDir.medium | tpl/string | `""` | emptyDir medium (e.g. "Memory" for tmpfs). Leave empty for node disk. |
| CONTROLLER.container.tmpDir.mountPath | tpl/string | `"/tmp"` | Mount path for the temporary directory volume. |
| CONTROLLER.container.tmpDir.sizeLimit | tpl/string | `""` | Maximum size of the emptyDir volume (e.g. "64Mi", "1Gi"). |
| CONTROLLER.container.workingDir | tpl/string | `""` | Working directory inside the container. |

### HorizontalPodAutoscaler

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| autoscaling.annotations | tpl/object | `{}` | Annotations to add to the HPA resource. |
| autoscaling.behavior | tpl/object | `{}` | HPA scaling behavior configuration. |
| autoscaling.maxReplicas | tpl/int | `nil` | Maximum number of replicas. |
| autoscaling.minReplicas | tpl/int | `nil` | Minimum number of replicas. |
| autoscaling.name | tpl/string | Release fullname | Name of the HPA resource. |
| autoscaling.targetCPUUtilizationPercentage | tpl/int | `nil` | Target average CPU utilization percentage. |
| autoscaling.targetMemoryUtilizationPercentage | tpl/int | `nil` | Target average memory utilization percentage. |

### ConfigMap

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| configMap.annotations | tpl/object | `{}` | Annotations to add to the ConfigMap metadata. |
| configMap.immutable | tpl/bool | `nil` | ensures that data stored in the ConfigMap cannot be updated. |
| configMap.name | tpl/string | Release fullname | Override the name of the ConfigMap. |

### CronJob

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cronjob.activeDeadlineSeconds | tpl/int | `nil` | Active deadline in seconds for a job. |
| cronjob.affinity | tpl/object | `.Values.global.affinity` | Affinity settings. |
| cronjob.backoffLimit | tpl/int | `nil` | Specifies the number of retries before marking this job failed. |
| cronjob.completions | tpl/int | `nil` | Desired number of successfully finished pods the job should be run with. |
| cronjob.concurrencyPolicy | tpl/string | `""` | Specifies how to treat concurrent executions of a Job. |
| cronjob.failedJobsHistoryLimit | tpl/int | `nil` | The number of failed finished jobs to retain. |
| cronjob.imagePullSecrets | tpl/list | `.Values.global.imagePullSecrets` | Image pull secrets for pod. |
| cronjob.name | tpl/string | Release fullname | Name of the CronJob. |
| cronjob.nodeSelector | tpl/object | `.Values.global.nodeSelector` | Node selector. |
| cronjob.parallelism | tpl/int | `nil` | Maximum desired number of pods the job should run at any given time. |
| cronjob.podAnnotations | tpl/object | `{}` | Pod annotations. |
| cronjob.podDnsConfig | tpl/object | `{}` | DNS configuration for the pod. |
| cronjob.podDnsPolicy | tpl/string | `""` | DNS policy for the pod. |
| cronjob.podFailurePolicyRules | tpl/list | `[]` | Rules for handling pod failures. |
| cronjob.podHostAliases | tpl/list | `[]` | An optional list of hosts and IPs that will be injected into the pod's hosts file if specified. |
| cronjob.podHostNetwork | tpl/bool | `nil` | Enable host networking. |
| cronjob.podHostname | tpl/string | `""` | Hostname of the pod. |
| cronjob.podSecurityContext | tpl/object | `{}` | Pod security context. |
| cronjob.podShareProcessNamespace | tpl/bool | `nil` | Share process namespace between containers. |
| cronjob.priorityClassName | tpl/string | `""` | Priority class name. |
| cronjob.restartPolicy | tpl/string | `"Never"` | Restart policy for containers. |
| cronjob.runtimeClassName | tpl/string | `""` | Runtime class name. |
| cronjob.schedule | tpl/string | `nil` | CronJob schedule in Cron format (required). |
| cronjob.startingDeadlineSeconds | tpl/int | `nil` | Number of seconds after which the job is considered failed if it hasn’t started. |
| cronjob.successfulJobsHistoryLimit | tpl/int | `nil` | The number of successful finished jobs to retain. |
| cronjob.suspend | tpl/bool | `false` | Whether to suspend subsequent executions. |
| cronjob.terminationGracePeriodSeconds | tpl/integer | `nil` | Termination grace period in seconds. |
| cronjob.tolerations | tpl/list | `.Values.global.tolerations` | Tolerations. |
| cronjob.topologySpreadConstraints | tpl/list | `[]` | Topology spread constraints. |
| cronjob.ttlSecondsAfterFinished | tpl/int | `nil` | Time in seconds to retain the job after it finishes. It is recommended to use this parameter for one-time jobs instead of a Helm hook that deletes the job immediately --> "helm.sh/hook-delete-policy": hook-succeeded. |

### DaemonSet

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| daemonset.affinity | tpl/object | `.Values.global.affinity` | Affinity rules for pod scheduling. |
| daemonset.annotations | tpl/object | `{}` | Annotations to add to the DaemonSet. |
| daemonset.imagePullSecrets | tpl/list | `.Values.global.imagePullSecrets` | Image pull secrets. |
| daemonset.minReadySeconds | tpl/int | `nil` | Minimum time in seconds for which a newly created pod should be ready. |
| daemonset.name | tpl/string | Release fullname | Name of the DaemonSet. |
| daemonset.nodeSelector | tpl/object | `.Values.global.nodeSelector` | Node selector for pod assignment. |
| daemonset.podAnnotations | tpl/object | `{}` | Annotations to add to the DaemonSet's pod template. |
| daemonset.podDnsConfig | tpl/object | `{}` | DNS configuration for pods. |
| daemonset.podDnsPolicy | tpl/string | `""` | DNS policy for pods. |
| daemonset.podHostAliases | tpl/list | `[]` | An optional list of hosts and IPs that will be injected into the pod's hosts file if specified. |
| daemonset.podHostNetwork | tpl/bool | `nil` | Use the host's network namespace. |
| daemonset.podHostname | tpl/string | `""` | Hostname of the pod. |
| daemonset.podSecurityContext | tpl/object | `{}` | Security context for the pod. |
| daemonset.podShareProcessNamespace | tpl/bool | `nil` | Enable process namespace sharing within pod. |
| daemonset.priorityClassName | tpl/string | `""` | Priority class name for the pod. |
| daemonset.revisionHistoryLimit | tpl/int | `10` | Number of old DaemonSet revisions to retain for rollback. |
| daemonset.runtimeClassName | tpl/string | `""` | Runtime class name for the pod. |
| daemonset.terminationGracePeriodSeconds | tpl/int | `nil` | Duration in seconds the pod needs to terminate gracefully. |
| daemonset.tolerations | tpl/list | `.Values.global.tolerations` | Tolerations for pod scheduling. |
| daemonset.topologySpreadConstraints | tpl/list | `[]` | Topology spread constraints for pods. |
| daemonset.updateStrategy | tpl/object | `{}` | Strategy used to replace old Pods by new ones. |

### Deployment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| deployment.affinity | tpl/object | `.Values.global.affinity` | Affinity rules for pod scheduling. |
| deployment.annotations | tpl/object | `{}` | Annotations to add to the deployment. |
| deployment.imagePullSecrets | tpl/list | `.Values.global.imagePullSecrets` | Image pull secrets. |
| deployment.minReadySeconds | tpl/int | `nil` | Minimum time in seconds for which a newly created pod should be ready. |
| deployment.name | tpl/string | Release fullname | Name of the deployment. |
| deployment.nodeSelector | tpl/object | `.Values.global.nodeSelector` | Node selector for pod assignment. |
| deployment.podAnnotations | tpl/object | `{}` | Annotations to add to the deployment's pod template. |
| deployment.podDnsConfig | tpl/object | `{}` | DNS configuration for pods. |
| deployment.podDnsPolicy | tpl/string | `""` | DNS policy for pods. |
| deployment.podHostAliases | tpl/list | `[]` | An optional list of hosts and IPs that will be injected into the pod's hosts file if specified. |
| deployment.podHostNetwork | tpl/bool | `nil` | Use the host's network namespace. |
| deployment.podHostname | tpl/string | `""` | Hostname of the pod. |
| deployment.podSecurityContext | tpl/object | `{}` | Security context for the pod. |
| deployment.podShareProcessNamespace | tpl/bool | `nil` | Enable process namespace sharing within pod. |
| deployment.priorityClassName | tpl/string | `""` | Priority class name for the pod. |
| deployment.replicaCount | tpl/int | `1` | Number of pod replicas (only if autoscaling is disabled). |
| deployment.revisionHistoryLimit | tpl/int | `10` | Number of old ReplicaSets to retain for rollback. |
| deployment.runtimeClassName | tpl/string | `""` | Runtime class name for the pod. |
| deployment.terminationGracePeriodSeconds | tpl/int | `nil` | Duration in seconds the pod needs to terminate gracefully. |
| deployment.tolerations | tpl/list | `.Values.global.tolerations` | Tolerations for pod scheduling. |
| deployment.topologySpreadConstraints | tpl/list | `[]` | Topology spread constraints for pods. |
| deployment.updateStrategy | tpl/object | `{}` | Strategy used to replace old Pods by new ones. |

### Diagnostic Mode

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| diagnosticMode.clusterRole.extraPermissionRules | tpl/list | `[]` | Additional RBAC cluster-wide rules required for diagnostic workloads. |
| diagnosticMode.role.extraPermissionRules | tpl/list | `[]` | Additional RBAC rules required for diagnostic workloads. |

### Global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.affinity | tpl/object | `{}` | Affinity rules to apply to all pods in all workloads. |
| global.applicationPartOf | string | The name of the current chart | The name of a higher level application this one is part of. It will be added to `app.kubernetes.io/part-of`. It usually makes sense to change this for a chart with subcharts that use this Helm library. |
| global.imagePullSecrets | tpl/list | `[]` | Image pull secrets for all containers. |
| global.imageRegistry | tpl/string | `""` | Global container image registry override. |
| global.nodeSelector | tpl/object | `{}` | Node selector to apply to all pods in all workloads. |
| global.timezone | tpl/string | `""` | Default timezone to configure in containers, if applicable. |
| global.tolerations | tpl/list | `[]` | Tolerations to apply to all pods in all workloads. |

### HTTPRoute

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| httpRoute.annotations | tpl/object | `{}` | Annotations to be added to the HTTPRoute. |
| httpRoute.hostnames | tpl/list | `[]` | Hostnames to match against the HTTP Host header. |
| httpRoute.name | tpl/string | Release fullname | Name of the HTTPRoute resource. |
| httpRoute.parentRefs | tpl/list | `[]` | Parent references (usually Gateways) to attach this route to. |
| httpRoute.rules | tpl/list | `[]` | HTTP routing rules. Rules without a backendRefs key use the chart Service; set backendRefs to [] to omit forwarding. |
| httpRoute.scheme | tpl/string | `"http"` | URL scheme used in HTTPRoute access instructions in NOTES. |

### Ingress

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ingress.annotations | tpl/object | `{}` | Annotations to be added to the ingress. |
| ingress.className | tpl/string | `""` | Ingress class name. |
| ingress.hosts | tpl/list | `[]` | Hosts and paths rules. |
| ingress.name | tpl/string | Release fullname | Name of the ingress resource. |
| ingress.tls | tpl/list | [] | TLS configuration for ingress. |

### Job

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| job.activeDeadlineSeconds | tpl/int | `nil` | Optional duration in seconds relative to the startTime that the job may be active before being terminated. |
| job.affinity | tpl/object | `.Values.global.affinity` | Affinity rules for the Pod. |
| job.annotations | tpl/object | `{}` | Metadata annotations for the Job. |
| job.backoffLimit | tpl/int | `nil` | Number of retries before marking this job as failed. |
| job.imagePullSecrets | tpl/list | `.Values.global.imagePullSecrets` | Pull secrets for job container image. |
| job.name | tpl/string | Release fullname | Name of the Job. |
| job.nodeSelector | tpl/object | `.Values.global.nodeSelector` | Node selector for the Pod. |
| job.podAnnotations | tpl/object | `{}` | Annotations to add to the job Pod. |
| job.podDnsConfig | tpl/object | `{}` | DNS config for the Pod. |
| job.podDnsPolicy | tpl/string | `""` | DNS policy for the Pod. |
| job.podHostAliases | tpl/list | `[]` | Host aliases for the Pod. |
| job.podHostNetwork | tpl/bool | `nil` | Enable host network for the Pod. |
| job.podHostname | tpl/string | `""` | Hostname for the Pod. |
| job.podSecurityContext | tpl/object | `{}` | Security context for the Pod. |
| job.podShareProcessNamespace | tpl/bool | `nil` | Share process namespace between containers. |
| job.priorityClassName | tpl/string | `""` | Priority class name for the Pod. |
| job.restartPolicy | tpl/string | `"Never"` | Restart policy for containers in the Pod (e.g., Never or OnFailure). |
| job.runtimeClassName | tpl/string | `""` | Runtime class name for the Pod. |
| job.terminationGracePeriodSeconds | tpl/int | `nil` | Duration the Pod needs to terminate gracefully. |
| job.tolerations | tpl/list | `.Values.global.tolerations` | Tolerations for the Pod. |
| job.topologySpreadConstraints | tpl/list | `[]` | Topology spread constraints for the Pod. |
| job.ttlSecondsAfterFinished | tpl/int | `3600` | Seconds to retain the job after it finishes. |

### NetworkPolicy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| networkPolicy.annotations | tpl/object | `{}` | Annotations to add to the NetworkPolicy metadata. |
| networkPolicy.egress | tpl/list | `[]` | List of egress rules applied to the selected pods. Traffic is allowed if it matches at least one rule. |
| networkPolicy.ingress | tpl/list | `[]` | List of ingress rules applied to the selected pods. Traffic is allowed if it matches at least one rule. |
| networkPolicy.name | tpl/string | Release fullname | Override the name of the NetworkPolicy. |
| networkPolicy.podSelector | tpl/object | Chart selector labels | Selects the pods to which this NetworkPolicy applies. Set to `{}` to select all pods in the namespace. |
| networkPolicy.policyTypes | tpl/list | `[]` | List of rule types the NetworkPolicy relates to. Valid values are "Ingress" and "Egress". |

### PodDisruptionBudget

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| pdb.annotations | tpl/object | `{}` | Annotations to add to the PodDisruptionBudget resource. |
| pdb.maxUnavailable | tpl/int | `1` | Number or percentage of pods that can be unavailable after eviction. Cannot be used with `minAvailable`. |
| pdb.minAvailable | tpl/int | `nil` | Number or percentage of pods that must be available after eviction. Cannot be used with `maxUnavailable`. |
| pdb.name | tpl/string | Release fullname | Name of the PodDisruptionBudget. |
| pdb.unhealthyPodEvictionPolicy | tpl/string | `""` | Unhealthy pod eviction policy. Valid values: "AlwaysAllow", "IfHealthyBudget". |

### ClusterRole

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| rbac.clusterRole.aggregationClusterRoleSelectors | tpl/list | `[]` | A list of label selector objects used to define aggregationRule.clusterRoleSelectors. |
| rbac.clusterRole.annotations | tpl/object | `{}` | Annotations to add to the ClusterRole metadata. |
| rbac.clusterRole.name | tpl/string | Release fullname | Override the name of the ClusterRole. |

### ClusterRoleBinding

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| rbac.clusterRoleBinding.annotations | tpl/object | `{}` | Annotations to add to the ClusterRoleBinding metadata. |
| rbac.clusterRoleBinding.name | tpl/string | Release fullname | Override the name of the ClusterRoleBinding. |

### Role

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| rbac.role.annotations | tpl/object | `{}` | Annotations to add to the Role metadata. |
| rbac.role.name | tpl/string | Release fullname | Override the name of the Role. |

### RoleBinding

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| rbac.roleBinding.annotations | tpl/object | `{}` | Annotations to add to the RoleBinding metadata. |
| rbac.roleBinding.name | tpl/string | Release fullname | Override the name of the RoleBinding. |

### Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secret.annotations | tpl/object | `{}` | Annotations to add to the Secret metadata. `{"helm.sh/hook":"pre-install,pre-upgrade","helm.sh/hook-weight":"1"}` are already added. |
| secret.immutable | tpl/bool | `nil` | ensures that data stored in the Secret cannot be updated. |
| secret.name | tpl/string | Release fullname | Override the name of the Secret. |

### Service

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| service.allocateLoadBalancerNodePorts | tpl/bool | `nil` | Allocate node ports for LoadBalancer-type Services. |
| service.annotations | tpl/object | `{}` | Annotations to add to the Service metadata. |
| service.clusterIP | tpl/string | `""` | ClusterIP address to assign to the Service. |
| service.externalIPs | tpl/list | `[]` | List of external IP addresses. |
| service.externalName | tpl/string | `""` | ExternalName for ExternalName-type Services. |
| service.externalTrafficPolicy | tpl/string | `""` | External traffic policy (e.g., Local or Cluster). |
| service.extraPorts | tpl/list | `[]` | Extra ports definitions to append to the Service. |
| service.healthCheckNodePort | tpl/int | `nil` | Health check node port. This only applies when type is set to LoadBalancer and externalTrafficPolicy is set to Local. |
| service.internalTrafficPolicy | tpl/string | `""` | Internal traffic policy. |
| service.ipFamilies | tpl/list | `[]` | IP families. Valid values are "IPv4" and "IPv6". |
| service.ipFamilyPolicy | tpl/string | `""` | IP family policy. |
| service.loadBalancerClass | tpl/string | `""` | Class of the LoadBalancer implementation. |
| service.loadBalancerIP | tpl/string | `""` | IP address for the LoadBalancer. |
| service.loadBalancerSourceRanges | tpl/list | `[]` | List of CIDR ranges allowed to access the LoadBalancer. |
| service.name | tpl/string | Release fullname | Override the name of the Service. |
| service.nodePort | tpl/int | `nil` | NodePort to expose when using NodePort/LoadBalancer. |
| service.port | tpl/int | `80` | Service port. |
| service.sessionAffinity | tpl/string | `""` | Session affinity setting. Supports "ClientIP" and "None". |
| service.sessionAffinityConfig | tpl/object | `{}` | Config for sessionAffinity. |
| service.trafficDistribution | tpl/string | `""` | Traffic distribution strategy. |
| service.type | tpl/string | `"ClusterIP"` | Service type. |

### ServiceAccount

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| serviceAccount.annotations | tpl/object | `{}` | Annotations to add to the ServiceAccount metadata. |
| serviceAccount.automountServiceAccountToken | tpl/bool | `nil` | Automatically mount the service account token. |
| serviceAccount.name | tpl/string | Release fullname | Override the name of the ServiceAccount. |

### VerticalPodAutoscaler

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| vpa.annotations | tpl/object | `{}` | Annotations to add to the VPA resource. |
| vpa.name | tpl/string | Release fullname | Name of the VPA resource. |
| vpa.recommenders | tpl/list | `[]` | Recommender responsible for generating the recommendation. Empty uses the default recommender. |
| vpa.resourcePolicy | tpl/object | `{}` | Controls how the autoscaler computes recommended resources (containerPolicies). |
| vpa.targetRef | tpl/object | Chart Deployment reference | Reference to the controller managing the set of pods to scale. |
| vpa.updatePolicy | tpl/object | `{}` | Rules on how changes are applied to the pods (e.g. updateMode, minReplicas). |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | tpl/string | `""` | Override the chart full name. |
| nameOverride | tpl/string | `""` | Override the chart full name from `{{ Release.Name }}-{{ .Chart.Name }}` to `{{ Release.Name }}-{{ .Values.nameOverride }}`. |
