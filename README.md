# chart-ccd

This chart is intended for deploying the full CCD product stack.
Including:
* data-store-api
* user-profile-api
* definition-store-api
* case-management-web (optional, enabled with a flag)

We will take small PRs and small features to this chart but more complicated needs should be handled in your own chart.

## Example configuration

Below is example configuration for running this chart on a PR to test your application with CCD, it could easily be tweaked to work locally if you wish, PRs to make that simpler are welcome.

requirements.yaml
```yaml
dependencies:
  - name: ccd
    version: '0.1.0'
    repository: '@hmcts'
```

The `SERVICE_FQDN`, `INGRESS_IP` and `CONSUL_LB_IP` are all provided by the pipeline, but require you to pass them through

values.template.yaml
```yaml
ccd:
  ingressHost: ${SERVICE_FQDN}
  ingressIP: ${INGRESS_IP}
  consulIP: ${CONSUL_LB_IP}

  apiGateway:
    s2sKey: ${API_GATEWAY_S2S_KEY}
    idamClientSecret: ${API_GATEWAY_IDAM_SECRET}

  dataStoreApi:
    s2sKey: ${DATA_STORE_S2S_KEY}

  definitionStoreApi:
    s2sKey: ${DEFINITION_STORE_S2S_KEY}

  caseManagementWeb:
   # enabled: true # if you need access to the web ui then enable this, otherwise it won't be deployed

```

The idam secret and s2s keys need to be loaded in the pipeline,
example config:

```
def secrets = [
  'your-vault-${env}': [
    secret('idam-client-secret', 'IDAM_CLIENT_SECRET') // optional, this is an example
  ],
  's2s-${env}'      : [
    secret('microservicekey-ccd-data', 'DATA_STORE_S2S_KEY'),
    secret('microservicekey-ccd-definition', 'DEFINITION_STORE_S2S_KEY'),
    secret('microservicekey-ccd-gw', 'API_GATEWAY_S2S_KEY'),
  ],
  'ccd-${env}'      : [
    secret('ccd-api-gateway-oauth2-client-secret', 'API_GATEWAY_IDAM_SECRET')
  ]
]

withPipeline(type, product, component) {
  loadVaultSecrets(secrets)
}
```

## Configuration

The following table lists the configurable parameters of the CCD chart and their default values.

If you need to change from the defaults consider sending a PR to the chart instead

| Parameter                  | Description                                | Default  |
| -------------------------- | ------------------------------------------ | ----- |
| `userProfileApi.image`          | User profile api's image version | `hmcts.azurecr.io/hmcts/ccd-user-profile-api:latest`|
| `userProfileApi.applicationPort`                    | Port user profile api runs on | `4453` |
| `userProfileApi.authorisedServices`              |  A list of services allowed to contact user profile api | `ccd_data,ccd_definition,ccd_admin`|
| `dataStoreApi.image`          | Data store api's image version | `hmcts.azurecr.io/hmcts/ccd-data-store-api:latest`|
| `dataStoreApi.applicationPort`                    | Port data store api runs on | `4452` |
| `dataStoreApi.s2sKey`                    | S2S key | `nil` (required must be set by user) |
| `dataStoreApi.authorisedServices`              |  A list of services allowed to contact data store api | See [values.yaml](ccd/values.yaml) (too many to list)|
| `definitionStoreApi.image`          | Definition store api's image version | `hmcts.azurecr.io/hmcts/ccd-definition-store-api:latest`|
| `definitionStoreApi.applicationPort`                    | Port definition store api runs on | `4451` |
| `definitionStoreApi.s2sKey`                    | S2S key | `nil` (required must be set by user) |
| `definitionStoreApi.authorisedServices`              |  A list of services allowed to contact definition store api | `ccd_data,ccd_gw,ccd_admin,jui_webapp,pui_webapp`|
| `caseManagementWeb.enabled`          | If case management web (and api gateway) will be deployed | `false`
| `caseManagementWeb.image`          | Case management web image version | `hmcts.azurecr.io/hmcts/ccd-case-management-web:latest`|
| `caseManagementWeb.applicationPort`                    | Port case management web runs on | `3451` |
| `apiGateway.image`          | Api gateway's image version | `hmcts.azurecr.io/hmcts/ccd-api-gateway-web:latest`|
| `apiGateway.applicationPort`                    | Port definition store api runs on | `3453` |
| `apiGateway.s2sKey`                    | S2S key | `nil` (required must be set by user) |
| `apiGateway.idamClientSecret`                    | Idam OAuth client secret | `nil` (required must be set by user) |
| `s2sUrl`                | S2S api url | `http://rpe-service-auth-provider-aat.service.core-compute-aat.internal`|
| `idamWebUrl`                | Idam web url | `https://idam.preprod.ccidam.reform.hmcts.net`|
| `idamApiUrl`                | Idam api url | `https://preprod-idamapi.reform.hmcts.net:3511`|
| `paymentsUrl`                | Payments api url | `http://payment-api-aat.service.core-compute-aat.internal`|
| `appInsightsKey`                | Application insights key for full CCD stack | `fake-key`|
| `memoryRequests`           | Requests for memory | `512Mi`|
| `cpuRequests`              | Requests for cpu | `100m`|
| `memoryLimits`             | Memory limits| `1024Mi`|
| `cpuLimits`                | CPU limits | `2500m`|
| `ingressHost`              | Host for ingress controller to map the container to | `nil` (required, provided by the pipeline)  |
| `ingressIP`              | Ingress controllers IP address | `nil` (required, provided by the pipeline)  |
| `consulIP`              | Consul servers IP address | `nil` (required, provided by the pipeline) |
| `readinessPath`            | Path of HTTP readiness probe | `/health`|
| `readinessDelay`           | Readiness probe inital delay (seconds)| `30`|
| `readinessTimeout`         | Readiness probe timeout (seconds)| `3`|
| `readinessPeriod`          | Readiness probe period (seconds) | `15`|
| `livenessPath`             | Path of HTTP liveness probe | `/health`|
| `livenessDelay`            | Liveness probe inital delay (seconds)  | `30`|
| `livenessTimeout`          | Liveness probe timeout (seconds) | `3`|
| `livenessPeriod`           | Liveness probe period (seconds) | `15`|
| `livenessFailureThreshold` | Liveness failure threshold | `3` |

## Development and Testing

Default configuration (e.g. default image and ingress host) is setup for sandbox. This is suitable for local development and testing.

- Ensure you have logged in with `az cli` and are using `sandbox` subscription (use `az account show` to display the current one).
- For local development see the `Makefile` for available targets.
- To execute an end-to-end build, deploy and test run `make`.
- to clean up deployed releases, charts, test pods and local charts, run `make clean`

`helm test` will deploy a busybox container alongside the release which performs a simple HTTP request against the service health endpoint. If it doesn't return `HTTP 200` the test will fail. **NOTE:** it does NOT run with `--cleanup` so the test pod will be available for inspection.

### Testing inside another chart locally

You can easily include this chart in another chart for testing:

requirements.yaml
```
  - name: ccd
    version: '>0.0.1'
    repository: file://<path-to-repository-can-be-relative-or-absolute>/chart-ccd/ccd
```

## Azure DevOps Builds
Builds are run against the 'nonprod' AKS cluster.

### Pull Request Validation
A build is triggered when pull requests are created. This build will run `helm lint`, deploy the chart using `ci-values.yaml` and run `helm test`.

### Release Build
Triggered when the repository is tagged (e.g. when a release is created). Also performs linting and testing, and will publish the chart to ACR on success.
