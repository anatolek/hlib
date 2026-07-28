# network-policy

![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.0.1](https://img.shields.io/badge/AppVersion-0.0.1-informational?style=flat-square)

A Helm chart for deploying NetworkPolicy resources

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://anatolek.github.io/helm-charts | hlib | >= 0.0.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| networkPolicy.egress | list | `[{"ports":[{"port":5432,"protocol":"TCP"}],"to":[{"ipBlock":{"cidr":"10.0.0.0/24"}}]},{"ports":[{"port":53,"protocol":"UDP"}],"to":[{"namespaceSelector":{"matchLabels":{"kubernetes.io/metadata.name":"kube-system"}}}]}]` | Allow egress to a database CIDR on TCP/5432 and DNS to the cluster. |
| networkPolicy.ingress | list | `[{"from":[{"podSelector":{"matchLabels":{"app.kubernetes.io/component":"frontend"}}}],"ports":[{"port":8080,"protocol":"TCP"}]}]` | Allow ingress traffic only from frontend pods on TCP/8080. |
| networkPolicy.policyTypes | list | `["Ingress","Egress"]` | Restrict the rule types that apply to the selected pods. |
