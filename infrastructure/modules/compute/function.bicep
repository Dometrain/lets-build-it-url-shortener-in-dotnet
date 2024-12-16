param location string
param appServicePlanName string
param name string
param keyVaultName string
@secure()
param storageAccountConnectionString string
param appSettings array = []

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    name: 'B1'
  }
}

resource function 'Microsoft.Web/sites@2023-12-01' = {
  kind: 'functionapp,linux'
  location: location
  name: name
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      linuxFxVersion: 'DOTNET-ISOLATED|8.0'
      alwaysOn: true
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      appSettings: concat(
        [
          {
            name: 'KeyVaultName'
            value: keyVaultName
          }
          {
            name: 'AzureWebJobsStorage'
            value: storageAccountConnectionString
          }
          {
            name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
            value: storageAccountConnectionString
          }
          {
            name: 'WEBSITE_CONTENTSHARE'
            value: toLower(name)
          }
          {
            name: 'FUNCTIONS_EXTENSION_VERSION'
            value: '~4'
          }
          {
            name: 'FUNCTIONS_WORKER_RUNTIME'
            value: 'dotnet-isolated'
          }
          {
            name: 'WEBSITE_RUN_FROM_PACKAGE'
            value: '1'
          }
        ],
        appSettings
      )
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource webAppConfig 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: function
  name: 'web'
  properties: {
    scmType: 'GitHub'
  }
}

output id string = function.id
output principalId string = function.identity.principalId
