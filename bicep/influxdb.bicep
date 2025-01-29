param prefix string
param location string
param publicIpId string
param subnetId string
param storageAccountName string
param privateDnsZoneName string

@secure()
param adminPassword string

param adminUsername string = 'infAdmin'
param osVersion string = 'server'
param vmSize string = 'Standard_B2as_v2'
param vmName string = 'influx'
param influxServerName string = '${prefix}-${vmName}-${uniqueString(resourceGroup().id)}'
param premiumDiskName string = '${prefix}-${vmName}-data-${uniqueString(resourceGroup().id)}'
param securityType string = 'TrustedLaunch'

var nicName = '${prefix}-${vmName}-nic-${uniqueString(resourceGroup().id)}'
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
var extensionName = 'GuestAttestation'
var extensionPublisher = 'Microsoft.Azure.Security.LinuxAttestation'
var extensionVersion = '1.0'
var maaTenantName = 'GuestAttestation'
var maaEndpoint = substring('emptyString', 0, 0)

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic' //maybe need to define it Static for proper DNS configuration
          publicIPAddress: {
            id: publicIpId
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource premiumDisk 'Microsoft.Compute/disks@2021-04-01' = {
  name: premiumDiskName
  location: location
  tags: {
    customer: 'customer1'
  }
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 128
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: influxServerName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: osVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          lun: 0
          name: premiumDisk.name
          createOption: 'Attach'
          managedDisk: {
            id: premiumDisk.id
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}

resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
  parent: vm
  name: extensionName
  location: location
  properties: {
    publisher: extensionPublisher
    type: extensionName
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: maaEndpoint
          maaTenantName: maaTenantName
        }
      }
    }
  }
}

resource dnsRecord 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  name: '${privateDnsZoneName}/${vmName}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: nic.properties.ipConfigurations[0].properties.privateIPAddress
      }
    ]
  }
}
