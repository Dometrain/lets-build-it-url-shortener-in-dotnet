param name string
param location string
param administratorLogin string
@secure()
param administratorLoginPassword string
param keyVaultName string
param subnetId string
param vnetId string

resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' = {
  name: name
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '16'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    network: {
      publicNetworkAccess: 'Disabled'
    }
  }
  resource database 'databases' = {
    name: 'ranges'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  location: location
  name: name
  properties: {
    subnet: {
      id: subnetId
    }
    customNetworkInterfaceName: '${name}-nic'
    privateLinkServiceConnections: [
      {
        name: name
        properties: {
          privateLinkServiceId: postgresqlServer.id
          groupIds: ['postgresqlServer']
        }
      }
    ]
  }
  tags: {}
  dependsOn: []
}

var privateDnsZoneName = 'privatelink.postgres.database.azure.com'
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDnsZoneVNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-dblink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-03-01' = {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-postgres-database-azure-com'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource cosmosDbConnectionString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'Postgres--ConnectionString'
  properties: {
    value: 'Server=${postgresqlServer.name}.postgres.database.azure.com;Database=ranges;Port=5432;User Id=${administratorLogin};Password=${administratorLoginPassword};Ssl Mode=Require;' // IMPORTANT: Use an applicaiton user for production
  }
}

output serverId string = postgresqlServer.id
