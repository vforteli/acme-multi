param Location string
param Name string
param ACRName string

resource aks 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: '${Name}-aks'
  location: Location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  properties: {
    dnsPrefix: '${Name}-dns'
    kubernetesVersion: '1.30.6'
    workloadAutoScalerProfile: {
      keda: {
        enabled: true
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
    networkProfile: {
      networkPolicy: 'azure'
    }
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
      }
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    ingressProfile: {
      webAppRouting: {
        enabled: true
      }
    }
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 1
        vmSize: 'Standard_B2s'
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        kubeletDiskType: 'OS'
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        maxCount: 3
        minCount: 1
        enableAutoScaling: true
        orchestratorVersion: '1.30.6'
        mode: 'System'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
      }
      {
        name: 'stuffarm64v6'
        count: 1
        vmSize: 'Standard_D2ps_v6'
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        kubeletDiskType: 'OS'
        maxPods: 30
        type: 'VirtualMachineScaleSets'
        maxCount: 3
        minCount: 1
        enableAutoScaling: true
        orchestratorVersion: '1.30.6'
        mode: 'User'
        osType: 'Linux'
        osSKU: 'Ubuntu'
      }
    ]
  }
}

resource acrPullRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: ACRName
}

resource aksAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, aks.id, acrPullRoleDefinition.id)
  scope: acr
  properties: {
    principalType: 'ServicePrincipal'
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    roleDefinitionId: acrPullRoleDefinition.id
  }
}

module azurekeyvaultsecretsprovider 'azurekeyvaultsecretsprovider.bicep' = {
  name: 'azurekeyvaultsecretsprovider'
  params: {
    AKSName: aks.name
    AKSResourceGroupName: aks.properties.nodeResourceGroup
  }
}

output aksNodeResourceGroupName string = aks.properties.nodeResourceGroup
output azurekeyvaultsecretsproviderPrincipalId string = azurekeyvaultsecretsprovider.outputs.azurekeyvaultsecretsproviderPrincipalId
output aksOidcIssuerUrl string = aks.properties.oidcIssuerProfile.issuerURL

resource kedaUser 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${Name}-keda-sp'
  location: resourceGroup().location

  resource federatedCredential 'federatedIdentityCredentials' = {
    name: 'federatedCredential'
    properties: {
      audiences: ['api://AzureADTokenExchange']
      issuer: aks.properties.oidcIssuerProfile.issuerURL
      subject: 'system:serviceaccount:kube-system:keda-operator'
    }
  }
}

resource serviceBusReceiverRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
}

resource sbReceiverRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, resourceGroup().name, 'keda', serviceBusReceiverRole.name)
  scope: resourceGroup()
  properties: {
    principalType: 'ServicePrincipal'
    principalId: kedaUser.properties.principalId
    roleDefinitionId: serviceBusReceiverRole.id
  }
}
