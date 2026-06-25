# vpa

![Version: 1.29.0](https://img.shields.io/badge/Version-1.29.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.29](https://img.shields.io/badge/AppVersion-1.29-informational?style=flat-square)

A Helm chart demonstrating the Vertical Pod Autoscaler

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://anatolek.github.io/helm-charts | hlib | >= 0.0.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| diagnosticMode.enabled | bool | `false` | Whether to enable diagnostic mode |
| vpa.enabled | bool | `true` | Whether to enable the Vertical Pod Autoscaler. |
| vpa.resourcePolicy | object | `{"containerPolicies":[{"containerName":"*","controlledResources":["cpu","memory"],"maxAllowed":{"cpu":"1","memory":"512Mi"},"minAllowed":{"cpu":"50m","memory":"64Mi"}}]}` | Per-container resource policy boundaries. |
| vpa.updatePolicy | object | `{"updateMode":"Recreate"}` | VPA update mode (Off, Initial, Recreate, InPlaceOrRecreate, InPlace; Auto is deprecated). |
