extension microsoftGraph

param applicationName string
@allowed([
  'AzureADMyOrg'
  'AzureADMultipleOrgs'
  'AzureADandPersonalMicrosoftAccount'
])
param signInAudience string = 'AzureADandPersonalMicrosoftAccount'

resource application 'Microsoft.Graph/applications@v1.0' = {
  displayName: applicationName
  uniqueName: applicationName
  signInAudience: signInAudience
}

resource updateApplicationWithSettings 'Microsoft.Graph/applications@v1.0' = {
  displayName: applicationName
  uniqueName: applicationName
  signInAudience: signInAudience
  api: {
    oauth2PermissionScopes: [
      {
        id: '9dbfb9bb-532d-47b7-9f2d-e458e9cba8a9'
        isEnabled: true
        value: 'Urls.Read'
        type: 'User'
        adminConsentDescription: 'URLs Read'
        adminConsentDisplayName: 'Urls Read'
        userConsentDescription: null
        userConsentDisplayName: 'Read Access to Urls'
      }
    ]
  }
  identifierUris: [
    'api://${application.appId}'
  ]
}

output appId string = application.appId
