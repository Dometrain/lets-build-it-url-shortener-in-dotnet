param location string
param name string
param subnets array

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  location: location
  name: name
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          delegations: subnet.delegations
          serviceEndpoints: subnet.serviceEndpoints
        }
      }
    ]
  }
}
