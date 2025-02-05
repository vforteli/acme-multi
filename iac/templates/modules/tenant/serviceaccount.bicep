param Tags object
param TenantName string
param AksOidcIssuerUrl string

param ServiceAccountName string
param ServicePrincipalName string

resource backendUser 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  tags: Tags
  name: ServicePrincipalName
  location: resourceGroup().location

  resource federatedCredential 'federatedIdentityCredentials' = {
    name: 'federatedCredential'
    properties: {
      audiences: ['api://AzureADTokenExchange']
      issuer: AksOidcIssuerUrl
      subject: 'system:serviceaccount:${TenantName}:${ServiceAccountName}'
    }
  }
}

output serviceAccountName string = ServiceAccountName
output servicePrincipalId string = backendUser.properties.principalId
output serviceClientId string = backendUser.properties.clientId
