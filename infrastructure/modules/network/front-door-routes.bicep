param profileName string
param endpointName string
param uniqueId string
param redirectApiHostName string
param apiHostName string
param webHostName string
param customDomainId string

resource profile 'Microsoft.Cdn/profiles@2024-02-01' existing = {
  name: profileName
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-02-01' existing = {
  parent: profile
  name: endpointName
}

// REDIRECT API
// --------------------

resource originRedirectGroup 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  parent: profile
  name: 'origin-group-redirect-${uniqueId}'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probeIntervalInSeconds: 120
      probePath: '/healthz'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
    }
  }
}

resource originRedirect 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  parent: originRedirectGroup
  name: 'origin-redirect'
  properties: {
    hostName: redirectApiHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: redirectApiHostName
    priority: 1
    weight: 1000
  }
}

resource routeRedirect 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-02-01' = {
  parent: endpoint
  name: 'redirect-route'
  properties: {
    originGroup: {
      id: originRedirectGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/r/*'
    ]
    originPath: '/r/'
    forwardingProtocol: 'MatchRequest'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    customDomains: [
      { id: customDomainId }
    ]
  }
  dependsOn: [
    originRedirect
  ]
}

// API
// --------------------

resource originApiGroup 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  parent: profile
  name: 'origin-group-api-${uniqueId}'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/healthz'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
  }
}

resource originApi 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  parent: originApiGroup
  name: 'origin-api'
  properties: {
    hostName: apiHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: apiHostName
    priority: 1
    weight: 1000
  }
}

resource routeApi 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-02-01' = {
  parent: endpoint
  name: 'api-route'
  properties: {
    originGroup: {
      id: originApiGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/api/*'
    ]
    originPath: '/api/'
    forwardingProtocol: 'MatchRequest'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    customDomains: [
      { id: customDomainId }
    ]
  }
  dependsOn: [
    originApi
  ]
}

// Web
// --------------------
resource originWebGroup 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  parent: profile
  name: 'origin-group-web-${uniqueId}'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
  }
}

resource originWeb 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  parent: originWebGroup
  name: 'origin-web'
  properties: {
    hostName: webHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: webHostName
    priority: 1
    weight: 1000
  }
}

resource routeWeb 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-02-01' = {
  parent: endpoint
  name: 'web-route'
  properties: {
    originGroup: {
      id: originWebGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    originPath: '/'
    forwardingProtocol: 'MatchRequest'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    customDomains: [
      { id: customDomainId }
    ]
    cacheConfiguration: {
      compressionSettings: {
        isCompressionEnabled: true
        contentTypesToCompress: [
          'text/html'
          'text/css'
          'application/javascript'
          'application/json'
          'image/svg+xml'
          'application/xml'
          'font/woff'
          'font/woff2'
          'font/ttf'
        ]
      }
      queryStringCachingBehavior: 'IgnoreQueryString'
    }
  }
  dependsOn: [
    originWeb
  ]
}

output endpointHostName string = endpoint.properties.hostName
