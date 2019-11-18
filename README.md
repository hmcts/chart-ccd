# chart-ccd


This chart is intended for deploying the full CCD product stack.
Including:
* data-store-api
* user-profile-api
* definition-store-api
Optional:
* case-management-web (optional, enabled with a flag)
* admin-web (optional, enabled with a flag)
* print-api (aka case-print-service which is optional, enabled with a flag)
* payment-api (which is optional, enabled with a flag)
* activity-api (aka ccd-case-activity-api which is optional, enabled with a flag)
*

We will take small PRs and small features to this chart but more complicated needs should be handled in your own chart.

## Example configuration

Below is example configuration for running this chart on a PR to test your application with CCD, it could easily be tweaked to work locally if you wish, PRs to make that simpler are welcome.

requirements.yaml
```yaml
dependencies:
  - name: ccd
    version: '2.0.0'
    repository: '@hmctspublic'
```

The `SERVICE_FQDN`, `INGRESS_IP` and `CONSUL_LB_IP` are all provided by the pipeline, but require you to pass them through for preview environments.

values.preview.yaml
```yaml

# Enable required services as follows
ccd:
  testStubsService:
    enabled: false
  definitionImporter:
    enabled: true
  userProfileImporter:
    enabled: true

global:
  ccdApiGatewayIngress: gateway-{{ .Release.Name }}.core-compute-preview.internal
  ccdCaseManagementWebIngress: www-{{ .Release.Name }}.core-compute-preview.internal
  ccdAdminWebIngress: ccd-admin-{{ .Release.Name }}.core-compute-preview.internal


ccd:
  ingressHost: ${SERVICE_FQDN}
  ingressIP: ${INGRESS_IP}
  consulIP: ${CONSUL_LB_IP}

  idam-pr:
    releaseNameOverride: ${SERVICE_NAME}-ccd-idam-pr
    redirect_uris:
      CCD:
        - https://case-management-web-${SERVICE_FQDN}/oauth2redirect
      CCD Admin:
        - https://admin-web-${SERVICE_FQDN}/oauth2redirect

  apiGateway:
    s2sKey: ${API_GATEWAY_S2S_KEY}
    idamClientSecret: 
      value: ${API_GATEWAY_IDAM_SECRET}

  userProfileApi:
    authorisedServices: ccd_admin,ccd_data,ccd_definition,cmc_claim_store

  dataStoreApi:
    s2sKey: ${DATA_STORE_S2S_KEY}
    s2sAuthorisedServices: cmc_claim_store,ccd_gw

  definitionStoreApi:
    s2sKey: ${DEFINITION_STORE_S2S_KEY}
    s2sAuthorisedServices: ccd_admin,ccd_data,cmc_claim_store,ccd_gw

  caseManagementWeb:
    enabled: true # if you need access to the web ui then enable this, otherwise it won't be deployed
    environment:
      NODE_TLS_REJECT_UNAUTHORIZED: 0

  adminWeb:
    enabled: true # if you need access to the admin web ui then enable this, otherwise it won't be deployed
    s2sKey: ${ADMIN_S2S_KEY}
    idamClientSecret: 
      value: ${ADMIN_WEB_IDAM_SECRET}
    environment:
      NODE_TLS_REJECT_UNAUTHORIZED: 0
```

## PostgreSQL

Persistance is enabled on this chart.  Due to stability issues with PVC's in the Preview environment, please disable persistance in consumers of this chart.

## Importers

In addition to the core services you can include some helper pods to import definitions and user profiles:

- definitions: https://github.com/hmcts/ccd-docker-definition-importer
- user profiles: https://github.com/hmcts/ccd-docker-user-profile-importer

values.preview.yaml
```yaml
ccd:
  # above config for core services
  ccd-definition-importer:
    definitions:
      - https://github.com/hmcts/ccd-data-store-api/raw/master/src/aat/resources/CCD_CNP_27_AUTOTEST1.xlsx
    userRoles:
      - caseworker-autotest1
  ccd-user-profile-importer:
    users:
      - auto.test.cnp@gmail.com|AUTOTEST1|AAT_PRIVATE|TODO
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
    secret('microservicekey-ccd-ps', 'PRINT_S2S_KEY')
  ],
  'ccd-${env}'      : [
    secret('ccd-api-gateway-oauth2-client-secret', 'API_GATEWAY_IDAM_SECRET')
  ]
]

withPipeline(type, product, component) {
  loadVaultSecrets(secrets)
}
```

## Accessing an app using this chart on a pull request

DNS will be automatically registered for most of the CCD pods, the ccd component will be prefixed to the regular url,
The prefixes can be found here:
https://github.com/hmcts/chart-ccd/blob/master/ccd/templates/ingress.yaml#L23

An example url for accessing case management web would be:
```
https://case-management-web-sscs-cor-backend-pr-189.service.core-compute-preview.internal/
```

### IDAM whitelisting for web components

Managed using https://github.com/hmcts/chart-idam-pr (version 2.0.0 and above).

To enable add following to your values.preview.yaml:
```
tags:
  ccd-idam-pr: true

ccd:
  # other ccd config

  idam-pr:
    releaseNameOverride: ${SERVICE_NAME}-ccd-idam-pr
    redirect_uris:
      CCD:
        - https://case-management-web-${SERVICE_FQDN}/oauth2redirect
      CCD Admin:
        - https://admin-web-${SERVICE_FQDN}/oauth2redirect
```

## Configuration

The following table lists the configurable parameters of the CCD chart and their default values.

If you need to change from the defaults consider sending a PR to the chart instead

| Parameter                  | Description                                | Default  |
| -------------------------- | ------------------------------------------ | ----- |
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
| `s2sUrl`                | S2S api url | `http://rpe-service-auth-provider-aat.service.core-compute-aat.internal`|
| `idamWebUrl`                | Idam web url | `https://idam.preprod.ccidam.reform.hmcts.net`|
| `idamApiUrl`                | Idam api url | `https://preprod-idamapi.reform.hmcts.net:3511`|
| `paymentsUrl`                | Payments api url | `http://payment-api-aat.service.core-compute-aat.internal`|
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
| `adminWeb.enabled`          | If admin web will be deployed | `false`
| `adminWeb.image`          | Admin web image version | `hmcts.azurecr.io/hmcts/ccd-admin-web:latest`|
| `adminWeb.applicationPort`                    | Port admin web runs on | `3100` |
| `adminWeb.s2sKey`                    | S2S key | `nil` (required must be set by user) |
| `adminWeb.idamClientSecret`                    | Idam OAuth client secret key | `nil` (required must be set by user) |
| `apiGateway.image`          | Api gateway's image version | `hmcts.azurecr.io/hmcts/ccd-api-gateway-web:latest`|
| `apiGateway.applicationPort`                    | Port definition store api runs on | `3453` |
| `apiGateway.s2sKey`                    | S2S key | `nil` (required must be set by user) |
| `apiGateway.idamClientSecret`                    | Idam OAuth client secret | `nil` (required must be set by user) |
| `printApi.image`          | Case print service's image version | `hmcts.azurecr.io/hmcts/ccd-case-print-service:latest`|
| `printApi.enabled`          | If case print service will be deployed | `false`
| `printApi.applicationPort`                    | Port definition case print service runs on | `3100` |
| `printApi.s2sKey`                    | S2S key | `nil` (required must be set by user) |
| `printApi.probateTemplateUrl`        | Probate callback url | `nil` (required must be set by user) |
| `ccd.definitionImporter.enabled` | Enabling Definition importer | `false` |
| `ccd-definition-importerimage` | Definition importer image to use | `hmcts.azurecr.io/hmcts/ccd-definition-importer:latest` |
| `ccd-definition-importer.keyVaults` | Secret with credentials for accessing necessary key vaults in Azure | `kvcreds` |
| `ccd-definition-importer.secrets` | set these env varibales from kubernetes secrets | `nil` (set by user) |
| `ccd-definition-importer.definitions` | https://github.com/hmcts/ccd-docker-definition-importer#configuration : parameter:`CCD_DEF_URLS` | `nil` |
| `ccd-definition-importer.definitionFilename` | https://github.com/hmcts/ccd-docker-definition-importer#configuration : parameter:`CCD_DEF_FILENAME` | `nil` |
| `ccd-definition-importer.waitHosts` | https://github.com/hmcts/ccd-docker-definition-importer#configuration : parameter:`WAIT_HOSTS` | `nil` |
| `ccd-definition-importer.waitHostsTimeout` | https://github.com/hmcts/ccd-docker-definition-importer#configuration : parameter:`WAIT_HOSTS_TIMEOUT` | `300` |
| `ccd-definition-importer.userRoles` | https://github.com/hmcts/ccd-docker-definition-importer#configuration : parameter:`USER_ROLES` | `- caseworker-bulkscan` |
| `ccd-definition-importer.microservice` | https://github.com/hmcts/ccd-docker-definition-importer#configuration : parameter:`MICROSERVICE` | `ccd_gw` |
| `ccd-definition-importer.verbose` | https://github.com/hmcts/ccd-docker-definition-importer#configuration : parameter:`VERBOSE` | `false` |
| `ccd.userProfileImporter.enabled` | Enabling User Profile importer | `false` |
| `ccd-user-profile-importer.image` | User Profile importer image to use | `hmcts.azurecr.io/hmcts/ccd-user-profile-importer:latest` |
| `ccd-user-profile-importer.users` | https://github.com/hmcts/ccd-docker-user-profile-importer#configuration : parameter=`CCD_USERS` | `nil` |
| `ccd-user-profile-importermicroservice` | https://github.com/hmcts/ccd-docker-user-profile-importer#configuration : parameter=`MICROSSERVICE` | `ccd_definition` |
| `ccd-user-profile-importer.waitHosts` | https://github.com/hmcts/ccd-docker-user-profile-importer#configuration : parameter=`WAIT_HOSTS` | `nil` |
| `ccd-user-profile-importer.waitHostsTimeout` | https://github.com/hmcts/ccd-docker-user-profile-importer#configuration : parameter=`WAIT_HOSTS_TIMEOUT` | `300` |
| `ccd-user-profile-importer.verbose` | https://github.com/hmcts/ccd-docker-user-profile-importer#configuration : parameter=`VERBOSE` | `false` |

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
    version: '>1.0.0'
    repository: file://<path-to-repository-can-be-relative-or-absolute>/chart-ccd/ccd
```

## Azure DevOps Builds
Builds are run against the 'nonprod' AKS cluster.

### Pull Request Validation
A build is triggered when pull requests are created. This build will run `helm lint`, deploy the chart using `ci-values.yaml` and run `helm test`.

### Release Build
Triggered when the repository is tagged (e.g. when a release is created). Also performs linting and testing, and will publish the chart to ACR on success.
 
