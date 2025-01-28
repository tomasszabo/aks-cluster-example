
param location string
param prefix string
param keyVaultName string
param publicIpAddressId string
param subnetAppGatewayId string

param appGatewayName string = '${prefix}-app-gw-${uniqueString(resourceGroup().id)}'
param appGatewayIdentityId string = '${prefix}-app-gw-identity-${uniqueString(resourceGroup().id)}'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource appGatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: appGatewayIdentityId
  location: location
}

resource appGateway 'Microsoft.Network/applicationGateways@2023-02-01' = {
  name: appGatewayName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGatewayIdentity.id}': {}
    }
  }
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetAppGatewayId
          }
        }
      }
    ]
    sslPolicy: {
      minProtocolVersion: 'TLSv1_2'
      policyType: 'Custom'
      cipherSuites: [        
         'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256'
         'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384'
         'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
         'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384'
         'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256'
         'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384'
         'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256'
         'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384'
      ]      
    }    
    trustedRootCertificates: []
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddressId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'customer1pool'
        properties: {
          backendAddresses: [
            {
              fqdn: 'customer1.private.metris.com'
            }
          ]
        }
      }
      {
        name: 'customer2pool'
        properties: {
          backendAddresses: [
            {
              fqdn: 'customer2.private.metris.com'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'customer1setting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          affinityCookieName: 'ApplicationGatewayAffinity'
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'customer1probe')
          }
        }
      }
      {
        name: 'customer2setting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          affinityCookieName: 'ApplicationGatewayAffinity'
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'customer2probe')
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: 'defaultSslCert'
        properties: {
          data: loadFileAsBase64('./certificate.pfx')
          password: 'appGWSSL'
        }
      }
    ]
    httpListeners: [
      {
        name: 'customer1listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_443')
          }
          protocol: 'Https'
          hostName: 'hackathon1.gad.andritz.com'
          requireServerNameIndication: false
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, 'defaultSslCert')
          }
        }
      }
      {
        name: 'customer2listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_443')
          }
          protocol: 'Https'
          hostName: 'hackathon2.gad.andritz.com'
          requireServerNameIndication: false
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, 'defaultSslCert')
          }
        }
      }
    ]
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'customer1rule'
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName,'customer1listener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'customer1pool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'customer1setting')
          }
        }
      }
      {
        name: 'customer2rule'
        properties: {
          ruleType: 'Basic'
          priority: 2
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName,'customer2listener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'customer2pool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'customer2setting')
          }
        }
      }
    ]
    probes: [
      {
        name: 'customer1probe'
        properties: {
          protocol: 'Http'
          path: '/health'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
      {
        name: 'customer2probe'
        properties: {
          protocol: 'Http'
          path: '/health'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    redirectConfigurations: []
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      disabledRuleGroups: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 2
      maxCapacity: 3
    }
  }
}

var keyVaultCertificatesUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba')

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, appGateway.id, keyVaultCertificatesUserRoleDefinitionId)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultCertificatesUserRoleDefinitionId
    principalId: appGatewayIdentity.properties.principalId
  }
}

output appGatewayId string = appGateway.id
