param Location string = resourceGroup().location

@minLength(5)
@maxLength(10)
param Name string = 'tkjfse'

param AdminUsername string = 'mysqladmin'
@secure()
param AdminPassword string = 'verysecurepassword123'

/////////////////////////////////////////////////////////////////
// Common components, such as AKS, Database server etc
module common 'modules/common.bicep' = {
  name: 'common'
  params: {
    Location: Location
    Name: Name
    AdminUsername: AdminUsername
    AdminPassword: AdminPassword
  }
}

/////////////////////////////////////////////////////////////////
// Tenants begin here

module acmeDrilling 'modules/tenant.bicep' = {
  name: 'acmeDrilling'
  params: {
    TenantName: 'acmedrilling'
    MySQLServerName: common.outputs.mysqlServerName
    AzureKeyvaulProviderClientId: common.outputs.azurekeyvaultsecretsproviderPrincipalId
    AksOidcIssuerUrl: common.outputs.aksOidcIssuerUrl
  }
}

module acmeOverseas 'modules/tenant.bicep' = {
  name: 'acmeOverseas'
  params: {
    TenantName: 'acmeoverseas'
    MySQLServerName: common.outputs.mysqlServerName
    AzureKeyvaulProviderClientId: common.outputs.azurekeyvaultsecretsproviderPrincipalId
    AksOidcIssuerUrl: common.outputs.aksOidcIssuerUrl
  }
}

// module acmemegacorp 'modules/tenant.bicep' = {
//   name: 'acmemegacorp'
//   params: {
//     TenantName: 'acmemegacorp'
//     MySQLServerName: MySQLServerName
//     AzureKeyvaulProviderClientId: common.outputs.azurekeyvaultsecretsproviderPrincipalId
//   }
// }
