# httproute

![Version: 1.29](https://img.shields.io/badge/Version-1.29-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.29](https://img.shields.io/badge/AppVersion-1.29-informational?style=flat-square)

A Helm chart for deploying HTTPRoute with Gateway API

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://anatolek.github.io/helm-charts | hlib | >= 0.0.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| diagnosticMode.enabled | bool | `false` | Whether to enable diagnostic mode |
| httpRoute.enabled | bool | `true` | Whether to enable HTTPRoute. |
| httpRoute.hostnames[0] | string | `"app.example.com"` |  |
| httpRoute.parentRefs[0].name | string | `"gateway"` |  |
| httpRoute.parentRefs[0].namespace | string | `"gateway-system"` |  |
| httpRoute.parentRefs[0].sectionName | string | `"https"` |  |
| httpRoute.rules[0].matches[0].path.type | string | `"PathPrefix"` |  |
| httpRoute.rules[0].matches[0].path.value | string | `"/"` |  |
