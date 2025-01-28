@description('The location of the Managed Cluster resource.')
param location string = 'westeurope'

@description('The prefix of the Managed Cluster resource.')
param prefix string = 'aks'

module network 'network.bicep' = {
  name: 'network'
  params: {
    location: location
    prefix: prefix
  }
}

module dnsZone 'dnszone.bicep' = {
  name: 'dnsZone'
  params: {
    vnetId: network.outputs.vnetId
  }
}

module keyVault 'keyVault.bicep' = {
  name: 'keyVault'
  params: {
    location: location
    prefix: prefix
  }
}

// module appGateway 'gateway.bicep' = {
//   name: 'gateway'
//   params: {
//     location: location
//     prefix: prefix
//     publicIpAddressId: network.outputs.gatewayIpAddressId
//     subnetAppGatewayId: network.outputs.subnetAppGatewayId
//     cnames: network.outputs.cnames
//     paths: paths
//     kubernetesIpAddress: network.outputs.kubernetesIpAddress
//   }
// }

module registry 'registry.bicep' = {
  name: 'registry'
  params: {
    location: location
    prefix: prefix
  }
}

module kubernetes 'kubernetes.bicep' = {
  name: 'kubernetes'
  params: {
    location: location
    prefix: prefix
    kubernetesSubnetId: network.outputs.subnetAksId
    registryName: registry.outputs.registryName
    keyVaultName: keyVault.outputs.keyVaultName
  }
}

module sqlServer 'sqlserver.bicep' = {
  name: 'sqlServer'
  params: {
    location: location
    prefix: prefix
  }
}

module influxDb 'influxdb.bicep' = {
  name: 'influxDb'
  params: {
    location: location
    prefix: prefix
  }
}
