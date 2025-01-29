param location string
param prefix string
param vnetId string
param subnetPrivateEndpointsId string
param endpoints array

var suffix = uniqueString(resourceGroup().id)

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = [for (endpoint, i) in endpoints: {
  name: '${prefix}-${endpoint.name}-pe-${suffix}'
  location: location
  tags: endpoint.tags
  properties: {
    subnet: {
      id: subnetPrivateEndpointsId
    }
    privateLinkServiceConnections: [
      {
        name: '${prefix}-${endpoint.name}-pe-conn-${suffix}'
        properties: {
          privateLinkServiceId: endpoint.serviceId
          groupIds: endpoint.groupIds
        }
      }
    ]
  }
}]

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = [for (endpoint, i) in endpoints: {
  name: endpoint.dnsZoneName
  location: 'global'
  properties: {}
}]

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (endpoint, i) in endpoints: {
  parent: privateDnsZone[i]
  name: '${privateDnsZone[i].name}-link-${suffix}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}]

resource privateDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = [for (endpoint, i) in endpoints: {
  parent: privateEndpoint[i]
  name: '${privateEndpoint[i].name}-dns-group-${suffix}'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateDnsZone[i].id
        }
      }
    ]
  }
}]
