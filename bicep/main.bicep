@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location

@description('The prefix of the Managed Cluster resource.')
param prefix string = 'aks'

@secure()
param sqlAdminPassword string

@secure()
param influxAdminPassword string = sqlAdminPassword

module storage 'storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    prefix: prefix
  }
}

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

module appGateway 'gateway.bicep' = {
  name: 'gateway'
  params: {
    location: location
    prefix: prefix
    publicIpAddressId: network.outputs.gatewayIpAddressId
    subnetAppGatewayId: network.outputs.subnetAppGatewayId
    keyVaultName: keyVault.outputs.keyVaultName
  }
}

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
    aksCustomer1SubnetId: network.outputs.subnetAksCustomer1Id 
    registryName: registry.outputs.registryName
    keyVaultName: keyVault.outputs.keyVaultName
    privateDnsZoneId: dnsZone.outputs.privateDnsZoneId
    vnetId: network.outputs.vnetId
  }
}

module sqlServer 'sqlserver.bicep' = {
  name: 'sqlServer'
  params: {
    location: location
    prefix: prefix
    adminPassword: sqlAdminPassword
    publicIpId: network.outputs.mssqlIpAddressId
    subnetId: network.outputs.subsnetVMId
    storageAccountName: storage.outputs.storageAccountName
    privateDnsZoneName: dnsZone.outputs.privateDnsZoneName
  }
}

module influxDb 'influxdb.bicep' = {
  name: 'influxDb'
  params: {
    location: location
    prefix: prefix
    adminPassword: influxAdminPassword
    publicIpId: network.outputs.influxIpAddressId
    subnetId: network.outputs.subsnetVMId
    storageAccountName: storage.outputs.storageAccountName
    privateDnsZoneName: dnsZone.outputs.privateDnsZoneName
  }
}

module privateEndpointsModule 'private-endpoints.bicep' = {
  name: 'privateEndpointsModule'
  params: {
    location: location
    prefix: prefix
    vnetId: network.outputs.vnetId
    subnetPrivateEndpointsId: network.outputs.subnetPrivateEndpointsId
    endpoints: [
      {
        name: 'storage-blob'
        dnsZoneName: 'privatelink.blob.${environment().suffixes.storage}'
        groupIds: ['blob']
        serviceId: storage.outputs.storageAccountId
        tags: {
          customer: 'customer1'
        }
      }
      {
        name: 'storage-file'
        dnsZoneName: 'privatelink.file.${environment().suffixes.storage}'
        groupIds: ['file']
        serviceId: storage.outputs.storageAccountId
        tags: {
          customer: 'customer1'
        }
      }
      {
        name: 'storage-queue'
        dnsZoneName: 'privatelink.queue.${environment().suffixes.storage}'
        groupIds: ['queue']
        serviceId: storage.outputs.storageAccountId
        tags: {
          customer: 'customer1'
        }
      }
      {
        name: 'storage-table'
        dnsZoneName: 'privatelink.table.${environment().suffixes.storage}'
        groupIds: ['table']
        serviceId: storage.outputs.storageAccountId
        tags: {
          customer: 'customer1'
        }
      }
      {
        name: 'keyVault'
        dnsZoneName: 'privatelink.vaultcore.azure.net'
        groupIds: ['vault']
        serviceId: keyVault.outputs.keyVaultId
        tags: {}
      }
      {
        name: 'acr'
        dnsZoneName: 'privatelink.azurecr.io'
        groupIds: ['registry']
        serviceId: registry.outputs.registryId
        tags: {}
      }
    ]
  }
}
