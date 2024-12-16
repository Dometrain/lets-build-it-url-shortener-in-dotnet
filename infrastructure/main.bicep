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

module apiService 'modules/compute/appservice.bicep' = {
  name: 'apiDeployment'
  params: {
    appName: 'api-${uniqueId}'
    appServicePlanName: 'plan-api-${uniqueId}'
    location: location
    keyVaultName: keyVaultName
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
    ]
  }
  dependsOn: [
    keyVault
  ]
}

module tokenRangeService 'modules/compute/appservice.bicep' = {
  name: 'tokenRangeServiceDeployment'
  params: {
    appName: 'token-range-service-${uniqueId}'
    appServicePlanName: 'plan-token-range-${uniqueId}'
    location: location
    keyVaultName: keyVaultName
  }
  dependsOn: [
    keyVault
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

module keyVaultRoleAssignment 'modules/secrets/key-vault-role-assignment.bicep' = {
  name: 'keyVaultRoleAssignmentDeployment'
  params: {
    keyVaultName: keyVaultName
    principalIds: [
      apiService.outputs.principalId
      tokenRangeService.outputs.principalId
    ]
  }
  dependsOn: [
    keyVault
    apiService
    tokenRangeService
  ]
}

module entraApp 'modules/identity/entra-app.bicep' = {
  name: 'entraAppWeb'
  params: {
    applicationName: 'web-${uniqueId}'
  }
}
