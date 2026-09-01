# external-secrets

![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.0.1](https://img.shields.io/badge/AppVersion-0.0.1-informational?style=flat-square)

A Helm chart for deploying an ExternalSecret

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://anatolek.github.io/helm-charts | hlib | >= 0.0.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| externalSecrets.data | list | `[{"remoteRef":{"key":"prod/app","property":"token"},"secretKey":"app-token"}]` | Mapping between target Secret keys and provider data. |
| externalSecrets.dataFrom | list | `[{"extract":{"key":"prod/app/config"}}]` | Fetch all values from a provider secret. |
| externalSecrets.refreshInterval | string | `"1h"` | Refresh interval for syncing from the provider. |
| externalSecrets.secretStoreRef.kind | string | `"ClusterSecretStore"` | Kind of the SecretStore. |
| externalSecrets.secretStoreRef.name | string | `"aws-secrets-manager"` | Name of the SecretStore to fetch data from. |
| externalSecrets.target.creationPolicy | string | `"Owner"` | Creation policy for the resulting Secret. |
