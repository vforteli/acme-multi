// This thing sits in its own module to avoid some bicep and arm shenanigans
// Trying to read the identity principal id directly in the same scope is a no go

param AKSName string
param AKSResourceGroupName string

var identityName = 'azurekeyvaultsecretsprovider-${AKSName}'

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(AKSResourceGroupName)
  name: identityName
}

output azurekeyvaultsecretsproviderPrincipalId string = identity.properties.principalId
