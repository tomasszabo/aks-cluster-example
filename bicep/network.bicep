
param location string
param prefix string

param gatewayIpAddressName string = '${prefix}-public-ip-gw-${uniqueString(resourceGroup().id)}'
param vnetName string = '${prefix}-vnet-${uniqueString(resourceGroup().id)}'
param vnetAddressPrefix string = '10.0.0.0/16'
param subnetAppGatewayName string = 'app-gw'
param subnetAppGatewayPrefix string = '10.0.1.0/26'
param subnetVMName string = 'vm'
param subnetVMPrefix string = '10.0.2.0/26'
param subnetPrivateEndpointsName string = 'private-endpoints'
param subnetPrivateEndpointsPrefix string = '10.0.3.0/24'
param subnetAksName string = 'aks'
param subnetAksPrefix string = '10.0.4.0/24'
param nsgAppGatewayName string = '${prefix}-nsg-app-gw-${uniqueString(resourceGroup().id)}'
param nsgVMName string = '${prefix}-nsg-vm-${uniqueString(resourceGroup().id)}'
param mssqlIpAddressName string = '${prefix}-public-ip-mssql-${uniqueString(resourceGroup().id)}'
param influxIpAddressName string = '${prefix}-public-ip-influx-${uniqueString(resourceGroup().id)}'

resource mssqlIpAddress 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: mssqlIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource influxIpAddress 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: influxIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource gatewayIpAddress 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: gatewayIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: gatewayIpAddressName    
    }
  }
}

resource nsgAppGateway 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: nsgAppGatewayName
  location: location
  properties: {
    securityRules: [
      {
        name: 'HealthProbesInbound'
        properties: {
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
          protocol: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowTLSInbound'
        properties: {
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          protocol: 'Tcp'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPInbound'
        properties: {
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
          protocol: 'Tcp'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          protocol: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'HealthProbesOutbound'
        properties: {
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
          protocol: '*'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource vmSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: nsgVMName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetAppGatewayName
        properties: {
          addressPrefix: subnetAppGatewayPrefix
          networkSecurityGroup: {
            id: nsgAppGateway.id
          }
        }
      }
      {
        name: subnetAksName
        properties: {
          addressPrefix: subnetAksPrefix
        }
      }
      {
        name: subnetPrivateEndpointsName
        properties: {
          addressPrefix: subnetPrivateEndpointsPrefix
        }
      }
      {
        name: subnetVMName
        properties: {
          addressPrefix: subnetVMPrefix
          networkSecurityGroup: {
            id: vmSecurityGroup.id
          }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output gatewayIpAddressId string = gatewayIpAddress.id
output subnetAppGatewayId string = vnet.properties.subnets[0].id
output subnetAksCustomer1Id string = vnet.properties.subnets[1].id
output subnetPrivateEndpointsId string = vnet.properties.subnets[2].id
output mssqlIpAddressId string = mssqlIpAddress.id
output influxIpAddressId string = influxIpAddress.id
output subsnetVMId string = vnet.properties.subnets[3].id
