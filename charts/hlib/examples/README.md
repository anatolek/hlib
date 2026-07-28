# Chart examples

| Chart name             | Description                                                       |
|------------------------|-------------------------------------------------------------------|
| `env-variables`        | Different options for defining access to variables in a container |
| `rbac`                 | Create RBAC resources                                             |
| `subcharts`            | Deploying multiple deployments with subcharts                     |
| `cronjob`              | Create CronJob                                                    |
| `multiple-deployments` | Deploying multiple deployments with one chart                     |
| `simple-deployment`    | Complete chart for simple application                             |
| `init-deployment`      | Simple chart, a good start for deploying a new application |
| `volumes`              | Mounting secrets and configmaps as volumes                        |
| `network-policy`       | Create NetworkPolicy with ingress and egress rules               |

To render a chart try to run:

```shell
cd examples/<chart>
helm template test .
```
