@minLength(5)
@maxLength(10)
param Name string
param Location string
param AdminUsername string
@secure()
param AdminPassword string

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: '${Name}acr'
  location: Location
  sku: {
    name: 'Basic'
  }
}

resource mysqlServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' = {
  name: 'acme-multi-mysql-server'
  location: Location
  properties: {
    administratorLogin: AdminUsername
    administratorLoginPassword: AdminPassword
    version: '8.0.21'
    storage: {
      storageSizeGB: 100
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
  }
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
}

module aks 'aks.bicep' = {
  name: 'aks'
  params: {
    Location: Location
    Name: Name
    ACRName: acr.name
  }
}

output aksName string = aks.name
output mysqlServerName string = mysqlServer.name
output aksNodeResourceGroupName string = aks.outputs.aksNodeResourceGroupName
output azurekeyvaultsecretsproviderPrincipalId string = aks.outputs.azurekeyvaultsecretsproviderPrincipalId
output aksOidcIssuerUrl string = aks.outputs.aksOidcIssuerUrl
