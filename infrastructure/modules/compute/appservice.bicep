param location string = resourceGroup().location
param appServicePlanName string
param appName string
param keyVaultName string
param logAnalyticsWorkspaceId string
param vnetId string
param ipSecurityRestrictions array = []
param appSettings array = []

module appInsights '../telemetry/app-insights.bicep' = {
  name: '${appName}AppInsightsDeployment'
  params: {
    location: location
    name: 'app-insights-${appName}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  kind: 'linux'
  location: location
  name: appServicePlanName
  properties: {
    reserved: true
  }
  sku: {
    name: 'B1'
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    virtualNetworkSubnetId: vnetId
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      healthCheckPath: '/healthz'
      publicNetworkAccess: 'Enabled'
      ipSecurityRestrictionsDefaultAction: 'Deny'
      ipSecurityRestrictions: ipSecurityRestrictions
      scmIpSecurityRestrictionsDefaultAction: 'Deny'
      scmIpSecurityRestrictions: [
        {
          name: 'AllowGHDeploy'
          action: 'Allow'
          priority: 100
          tag: 'ServiceTag'
          ipAddress: 'AzureCloud'
        }
      ]
      appSettings: concat(
        [
          {
            name: 'KeyVaultName'
            value: keyVaultName
          }
          {
            name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
            value: appInsights.outputs.instrumentrationKey
          }
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: appInsights.outputs.connectionString
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
  parent: webApp
  name: 'web'
  properties: {
    scmType: 'GitHub'
  }
}

output appServiceId string = webApp.id
output principalId string = webApp.identity.principalId
output url string = 'https://${webApp.properties.defaultHostName}'
output hostname string = webApp.properties.defaultHostName
