param location string
param name string

resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' = {
  location: location
  name: name
  sku: {
    tier: 'Standard'
    name: 'Standard'
  }
  properties: {}
}

output id string = staticWebApp.id
output url string = 'https://${staticWebApp.properties.defaultHostname}'
output hostname string = staticWebApp.properties.defaultHostname
