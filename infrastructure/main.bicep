param location string = resourceGroup().location
@secure()
param pgSqlPassword string

var uniqueId = uniqueString(resourceGroup().id)
var keyVaultName = 'kv-${uniqueId}'

module keyVault 'modules/secrets/keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    vaultName: keyVaultName
    location: location
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
        value: '${redirectApiService.outputs.url}/r/'
      }
    ]
  }
  dependsOn: [
    keyVault
    logAnalyticsWorkspace
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
  }
  dependsOn: [
    keyVault
    logAnalyticsWorkspace
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
  }
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
  }
  dependsOn: [
    keyVault
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
    ]
  }
}

module redisCache 'modules/storage/redis-cache.bicep' = {
  name: 'redisCacheDeployment'
  params: {
    name: 'redis-cache-${uniqueId}'
    location: location
    keyVaultName: keyVaultName
  }
  dependsOn: [
    keyVault
  ]
}

module staticWebApp 'modules/web/static-web-app.bicep' = {
  name: 'staticWebAppDeployment'
  params: {
    name: 'web-app-${uniqueId}'
    location: location
  }
}
