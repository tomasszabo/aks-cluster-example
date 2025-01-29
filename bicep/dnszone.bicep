
param vnetId string

resource dnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'private.metris.com'
  location: 'global'
  properties: {
  }
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsZone
  name: 'vnet-dns-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

output privateDnsZoneId string = dnsZone.id
