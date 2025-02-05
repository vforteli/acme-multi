@description('TenantName is also used as the namespace in AKS')
param TenantName string
param MySQLServerName string
param AzureKeyvaulProviderClientId string
param AksOidcIssuerUrl string

var keyvaultName = '${TenantName}kv'
var databaseName = '${TenantName}db'
var tags = {
  tenantName: TenantName
  environment: 'poc'
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2024-01-01' = {
  name: '${TenantName}-sbn'
  tags: tags
  location: resourceGroup().location
  sku: { name: 'Basic' }

  resource blobCreatedEventQueue 'queues' = {
    name: 'something-happened'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyvaultName
  location: resourceGroup().location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
  }

  resource somesecret 'secrets' = {
    name: 'somesecret'
    properties: { value: 'somevalue' }
  }

  resource sbEndpointSecret 'secrets' = {
    name: 'sb-endpoint'
    properties: { value: serviceBus.properties.serviceBusEndpoint }
  }
}

resource server 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' existing = {
  name: MySQLServerName

  resource database 'databases@2023-12-30' = {
    name: databaseName
  }
}

resource keyVaultSecretsUserRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

resource akskv 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, keyVault.id, keyVaultSecretsUserRoleDefinition.id)
  scope: keyVault
  properties: {
    principalType: 'ServicePrincipal'
    principalId: AzureKeyvaulProviderClientId
    roleDefinitionId: keyVaultSecretsUserRoleDefinition.id
  }
}

module backendUserModule 'tenant/serviceaccount.bicep' = {
  name: 'backendUserModule${TenantName}'
  params: {
    AksOidcIssuerUrl: AksOidcIssuerUrl
    Tags: tags
    TenantName: TenantName
    ServiceAccountName: '${TenantName}-backend-sa'
    ServicePrincipalName: '${TenantName}-backend-sp'
  }
}

module workerUserModule 'tenant/serviceaccount.bicep' = {
  name: 'workerUserModule${TenantName}'
  params: {
    AksOidcIssuerUrl: AksOidcIssuerUrl
    Tags: tags
    TenantName: TenantName
    ServiceAccountName: '${TenantName}-worker-sa'
    ServicePrincipalName: '${TenantName}-worker-sp'
  }
}

resource serviceBusReceiverRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
}

resource serviceBusSenderRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
}

resource backendSbReceiver 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, serviceBus.name, TenantName, 'backend', serviceBusReceiverRole.name)
  scope: serviceBus
  properties: {
    principalType: 'ServicePrincipal'
    principalId: backendUserModule.outputs.servicePrincipalId
    roleDefinitionId: serviceBusReceiverRole.id
  }
}

resource backendSbSender 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, serviceBus.name, TenantName, 'backend', serviceBusSenderRole.name)
  scope: serviceBus
  properties: {
    principalType: 'ServicePrincipal'
    principalId: backendUserModule.outputs.servicePrincipalId
    roleDefinitionId: serviceBusSenderRole.id
  }
}

resource workerSbReceiver 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, serviceBus.name, TenantName, 'worker', serviceBusReceiverRole.name)
  scope: serviceBus
  properties: {
    principalType: 'ServicePrincipal'
    principalId: workerUserModule.outputs.servicePrincipalId
    roleDefinitionId: serviceBusReceiverRole.id
  }
}

output keyvaultName string = keyvaultName
output databaseName string = databaseName
output backendServiceAccountName string = backendUserModule.outputs.serviceAccountName
output workerServiceAccountName string = workerUserModule.outputs.serviceAccountName
