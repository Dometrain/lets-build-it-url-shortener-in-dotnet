param location string = resourceGroup().location
param vaultName string
param subnets array

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: vaultName
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableRbacAuthorization: true
    tenantId: subscription().tenantId
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        for subnetId in subnets: {
          id: subnetId
        }
      ]
    }
  }
}

output id string = keyVault.id
output name string = keyVault.name
