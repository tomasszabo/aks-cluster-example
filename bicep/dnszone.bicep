
param vnetId string

resource gatewayDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'private.metris.com'
  location: 'global'
  properties: {}
}

resource gatewayVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: gatewayDnsZone
  name: 'gateway-vnet-dns-link'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnetId
    }
  }
}

output privateDnsZoneId string = gatewayDnsZone.id
