param location string = resourceGroup().location
@secure()
param pgSqlPassword string
param customDomain string

var uniqueId = uniqueString(resourceGroup().id)
var keyVaultName = 'kv-${uniqueId}'
var vnetName = 'vnet-${uniqueId}'
var apiSubnetName = 'subnet-api-${uniqueId}'
var redirectApiSubnetName = 'subnet-redirect-${uniqueId}'
var tokenRangeSubnetName = 'subnet-token-range-${uniqueId}'
var cosmosTriggerSubnetName = 'subnet-cosmos-trigger-${uniqueId}'
var redisSubnetName = 'subnet-redis-${uniqueId}'
var postgresSubnetName = 'subnet-postgres-${uniqueId}'

module vnet 'modules/network/virtual-network.bicep' = {
  name: 'vnetDeployment'
  params: {
    name: vnetName
    location: location
    subnets: [
      {
        name: apiSubnetName
        addressPrefix: '10.0.1.0/24'
        delegations: [
          {
            name: 'Microsoft.Web/serverfarms'
            properties: {
              serviceName: 'Microsoft.Web/serverfarms'
            }
          }
        ]
        serviceEndpoints: [
          { service: 'Microsoft.KeyVault' }
          { service: 'Microsoft.AzureCosmosDB' }
          { service: 'Microsoft.Web' }
        ]
      }
      {
        name: redirectApiSubnetName
        addressPrefix: '10.0.2.0/24'
        delegations: [
          {
            name: 'Microsoft.Web/serverfarms'
            properties: {
              serviceName: 'Microsoft.Web/serverfarms'
            }
          }
        ]
        serviceEndpoints: [
          { service: 'Microsoft.KeyVault' }
          { service: 'Microsoft.AzureCosmosDB' }
        ]
      }
      {
        name: tokenRangeSubnetName
        addressPrefix: '10.0.3.0/24'
        delegations: [
          {
            name: 'Microsoft.Web/serverfarms'
            properties: {
              serviceName: 'Microsoft.Web/serverfarms'
            }
          }
        ]
        serviceEndpoints: [
          { service: 'Microsoft.KeyVault' }
          { service: 'Microsoft.SQL' }
        ]
      }
      {
        name: cosmosTriggerSubnetName
        addressPrefix: '10.0.4.0/24'
        delegations: [
          {
            name: 'Microsoft.Web/serverfarms'
            properties: {
              serviceName: 'Microsoft.Web/serverfarms'
            }
          }
        ]
        serviceEndpoints: [
          { service: 'Microsoft.Storage' }
          { service: 'Microsoft.KeyVault' }
          { service: 'Microsoft.AzureCosmosDB' }
        ]
      }
      {
        name: redisSubnetName
        addressPrefix: '10.0.5.0/24'
        delegations: []
        serviceEndpoints: []
      }
      {
        name: postgresSubnetName
        addressPrefix: '10.0.6.0/24'
        delegations: []
        serviceEndpoints: []
      }
    ]
  }
}

module keyVault 'modules/secrets/keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    vaultName: keyVaultName
    location: location
    subnets: [
      resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, apiSubnetName)
      resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, cosmosTriggerSubnetName)
      resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, tokenRangeSubnetName)
      resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, redirectApiSubnetName)
    ]
  }
}

module logAnalyticsWorkspace 'modules/telemetry/log-analytics.bicep' = {
  name: 'logAnalyticsWorkspaceDeployment'
  params: {
    location: location
    name: 'log-analytics-ws-${uniqueId}'
  }
}

module apiService 'modules/compute/appservice.bicep' = {
  name: 'apiDeployment'
  params: {
    appName: 'api-${uniqueId}'
    appServicePlanName: 'plan-api-${uniqueId}'
    location: location
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    vnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, apiSubnetName)
    ipSecurityRestrictions: [
      {
        name: 'AllowFrontDoor'
        action: 'Allow'
        priority: 100
        tag: 'ServiceTag'
        ipAddress: 'AzureFrontDoor.Backend'
      }
    ]
    appSettings: [
      {
        name: 'DatabaseName'
        value: 'urls'
      }
      {
        name: 'ContainerName'
        value: 'items'
      }
      {
        name: 'ByUserDatabaseName'
        value: 'urls'
      }
      {
        name: 'ByUserContainerName'
        value: 'byUser'
      }
      {
        name: 'TokenRangeService__Endpoint'
        value: tokenRangeService.outputs.url
      }
      {
        name: 'AzureAd__Instance'
        value: environment().authentication.loginEndpoint
      }
      {
        name: 'AzureAd__TenantId'
        value: tenant().tenantId
      }
      {
        name: 'AzureAd__ClientId'
        value: entraApp.outputs.appId
      }
      {
        name: 'AzureAd__Scopes'
        value: 'Urls.Read'
      }
      {
        name: 'WebAppEndpoints'
        value: '${staticWebApp.outputs.url},http://localhost:3000'
      }
      {
        name: 'RedirectService__Endpoint'
        value: 'https://${customDomain}/r/'
      }
    ]
  }
  dependsOn: [
    keyVault
    logAnalyticsWorkspace
    vnet
  ]
}

module tokenRangeService 'modules/compute/appservice.bicep' = {
  name: 'tokenRangeServiceDeployment'
  params: {
    appName: 'token-range-service-${uniqueId}'
    appServicePlanName: 'plan-token-range-${uniqueId}'
    location: location
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    vnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, tokenRangeSubnetName)
    ipSecurityRestrictions: [
      {
        tag: 'Default'
        action: 'Allow'
        priority: 100
        name: 'AllowApiSubnet'
        vnetSubnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, apiSubnetName)
      }
    ]
  }
  dependsOn: [
    keyVault
    logAnalyticsWorkspace
    vnet
  ]
}

module redirectApiService 'modules/compute/appservice.bicep' = {
  name: 'redirectApiServiceDeployment'
  params: {
    appName: 'redirect-api-${uniqueId}'
    appServicePlanName: 'plan-redirect-${uniqueId}'
    location: location
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    vnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, redirectApiSubnetName)
    ipSecurityRestrictions: [
      {
        name: 'AllowFrontDoor'
        action: 'Allow'
        priority: 100
        tag: 'ServiceTag'
        ipAddress: 'AzureFrontDoor.Backend'
      }
    ]
    appSettings: [
      {
        name: 'DatabaseName'
        value: 'urls'
      }
      {
        name: 'ContainerName'
        value: 'items'
      }
    ]
  }
  dependsOn: [
    keyVault
    logAnalyticsWorkspace
    vnet
  ]
}

module postgres 'modules/storage/postgresql.bicep' = {
  name: 'postgresDeployment'
  params: {
    name: 'postgresql-${uniqueString(resourceGroup().id)}'
    location: location
    administratorLogin: 'adminuser'
    administratorLoginPassword: pgSqlPassword
    keyVaultName: keyVaultName
    vnetId: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, postgresSubnetName)
  }
  dependsOn: [
    vnet
  ]
}

module cosmosDb 'modules/storage/cosmos-db.bicep' = {
  name: 'cosmosDbDeployment'
  params: {
    name: 'cosmos-db-${uniqueId}'
    location: location
    kind: 'GlobalDocumentDB'
    databaseName: 'urls'
    locationName: 'Spain Central'
    keyVaultName: keyVaultName
    subnets: [
      resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, apiSubnetName)
      resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, redirectApiSubnetName)
      resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, cosmosTriggerSubnetName)
    ]
  }
  dependsOn: [
    keyVault
    vnet
  ]
}

module storageAccount 'modules/storage/storage-account.bicep' = {
  name: 'storageAccountDeployment'
  params: {
    name: 'storage${uniqueId}'
    location: location
  }
}

module cosmosTriggerFunction 'modules/compute/function.bicep' = {
  name: 'cosmosTriggerFunctionDeployment'
  params: {
    appServicePlanName: 'plan-cosmos-trigger-${uniqueId}'
    name: 'cosmos-trigger-function-${uniqueId}'
    location: location
    keyVaultName: keyVaultName
    storageAccountConnectionString: storageAccount.outputs.storageConnectionString
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, cosmosTriggerSubnetName)
    appSettings: [
      {
        name: 'CosmosDbConnection'
        value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/CosmosDb--ConnectionString/)'
      }
      {
        name: 'TargetDatabaseName'
        value: 'urls'
      }
      {
        name: 'TargetContainerName'
        value: 'byUser'
      }
    ]
  }
  dependsOn: [
    keyVault
    storageAccount
    cosmosDb
    logAnalyticsWorkspace
    vnet
  ]
}

module keyVaultRoleAssignment 'modules/secrets/key-vault-role-assignment.bicep' = {
  name: 'keyVaultRoleAssignmentDeployment'
  params: {
    keyVaultName: keyVaultName
    principalIds: [
      apiService.outputs.principalId
      tokenRangeService.outputs.principalId
      redirectApiService.outputs.principalId
      cosmosTriggerFunction.outputs.principalId
    ]
  }
  dependsOn: [
    keyVault
    apiService
    tokenRangeService
    redirectApiService
    cosmosTriggerFunction
  ]
}

module entraApp 'modules/identity/entra-app.bicep' = {
  name: 'entraAppWeb'
  params: {
    applicationName: 'web-${uniqueId}'
    spaRedirectUris: [
      'http://localhost:3000/' // Not for PRD use
      staticWebApp.outputs.url
      'https://${frontDoor.outputs.endpointHostName}'
      'https://${customDomain}'
    ]
  }
}

module redisCache 'modules/storage/redis-cache.bicep' = {
  name: 'redisCacheDeployment'
  params: {
    name: 'redis-cache-${uniqueId}'
    location: location
    keyVaultName: keyVaultName
    vnetId: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, redisSubnetName)
  }
  dependsOn: [
    keyVault
    vnet
  ]
}

module staticWebApp 'modules/web/static-web-app.bicep' = {
  name: 'staticWebAppDeployment'
  params: {
    name: 'web-app-${uniqueId}'
    location: location
  }
}

module frontDoor 'modules/network/front-door.bicep' = {
  name: 'frontDoorDeployment'
  params: {
    endpointName: 'endpoint-${uniqueId}'
    profileName: 'front-door-${uniqueId}'
    wafPolicyName: 'waf${uniqueId}'
    customDomainName: customDomain
  }
}

module frontDoorRoutes 'modules/network/front-door-routes.bicep' = {
  name: 'frontDoorRoutesDeployment'
  params: {
    endpointName: 'endpoint-${uniqueId}'
    profileName: 'front-door-${uniqueId}'
    uniqueId: uniqueId
    redirectApiHostName: redirectApiService.outputs.hostname
    apiHostName: apiService.outputs.hostname
    webHostName: staticWebApp.outputs.hostname
    customDomainId: frontDoor.outputs.customDomainId
  }
  dependsOn: [
    redirectApiService
    apiService
    staticWebApp
  ]
}
