
param location string
param prefix string
param kubernetesSubnetId string
param registryName string
param keyVaultName string
param privateDnsZoneId string

param clusterName string = '${prefix}-aks-${uniqueString(resourceGroup().id)}'
param dnsPrefix string = prefix
param agentCount int = 1
param agentVMSize string = 'Standard_D8s_v3'
param kubernetesVersion string = '1.30.7'
param serviceCidr string = '10.4.0.0/16'
param dnsServiceIP string = '10.4.0.4'
param podCidr string = '10.244.0.0/16'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-09-02-preview' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Free' 
  }
  properties: {
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
        osDiskType: 'Ephemeral'
        vnetSubnetID: kubernetesSubnetId
      }
    ]
    kubernetesVersion: kubernetesVersion
    enableRBAC: true
    addonProfiles: {
      // Application routing add-on
      httpApplicationRouting: {
        enabled: true
        config: {
          zones: privateDnsZoneId
        }
      }

      // Azure Key Vault add-on
      azureKeyvaultSecretsProvider: {
        enabled: true
      }
    }
    ingressProfile: {
      webAppRouting: {
        enabled: true
        nginx: {
          defaultIngressControllerType: 'None'
        }
      }
    }
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      podCidr: podCidr
    }
  }
}

var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var aksId = aksCluster.id
var aksIdentityId = aksCluster.properties.identityProfile.kubeletidentity.objectId

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: registryName
}

resource pullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, aksId, acrPullRoleDefinitionId)
  scope: registry
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: aksIdentityId
    principalType: 'ServicePrincipal'
  }
}

var keyVaultSecretsUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, aksCluster.id, keyVaultSecretsUserRoleDefinitionId)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
    principalId: aksCluster.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.objectId
  }
}

module secret1 'keyVaultSecret.bicep' = {
  name: 'secret1'
  params: {
    keyVaultName: keyVaultName
    secretName: 'secret1'
    secretValue: 'this is a secret'
  }
}
