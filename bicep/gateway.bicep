
param location string
param prefix string

param publicIpAddressId string
param subnetAppGatewayId string
param cnames array
param paths array
param kubernetesIpAddress string

// param primaryBackendEndFQDN string

// param probeUrl string = '/status-0123456789abcdef'
param appGatewayName string = '${prefix}-app-gw-${uniqueString(resourceGroup().id)}'
// param appGatewayIdentityId string = '${prefix}-app-gw-identity-${uniqueString(resourceGroup().id)}'

// resource appGatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
//   name: appGatewayIdentityId
//   location: location
// }

resource appGateway 'Microsoft.Network/applicationGateways@2023-02-01' = {
  name: appGatewayName
  location: location
  identity: {
    type: 'SystemAssigned'
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
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'defaultaddresspool'
        properties: {
          backendAddresses: [
            {
              fqdn: 'customer1.private.metris.com'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'defaulthttpsetting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          affinityCookieName: 'ApplicationGatewayAffinity'
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'defaultProbe')
          }
        }
      }
      // {
      //   name: 'https'
      //   properties: {
      //     port: 443
      //     protocol: 'Https'
      //     cookieBasedAffinity: 'Disabled'
      //     hostName: primaryBackendEndFQDN
      //     pickHostNameFromBackendAddress: false
      //     requestTimeout: 20
      //     probe: {
      //       id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'APIM')
      //     }
      //   }
      // }
    ]
    httpListeners: [
      {
        name: 'default'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
      // {
      //   name: 'https'
      //   properties: {
      //     frontendIPConfiguration: {
      //       id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGwPublicFrontendIp')
      //     }
      //     frontendPort: {
      //       id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_443')
      //     }
      //     protocol: 'Https'
      //     sslCertificate: {
      //       id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, appGatewayFQDN)
      //     }
      //     hostNames: []
      //     requireServerNameIndication: false
      //   }
      // }
    ]
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'DefaultRuleName'
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName,'default')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'defaultaddresspool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'defaulthttpsetting')
          }
          rewriteRuleSet: {
            id: resourceId('Microsoft.Network/applicationGateways/rewriteRuleSets', appGatewayName, 'rewriteRuleSet')
          }
        }
      }
    ]
    probes: [
      {
        name: 'defaultProbe'
        properties: {
          protocol: 'Http'
          path: '/store/health'
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
    rewriteRuleSets: [
      {
        name: 'rewriteRuleSet'
        properties: {
          rewriteRules: [for (path, i) in paths: {
              name: path
              conditions: [
                {
                  ignoreCase: true
                  pattern: cnames[i]
                  negate: false
                  variable: 'http_req_Host'
                }
              ]
              actionSet: {
                urlConfiguration: { 
                  modifiedPath: '/${path}/{var_uri_path}'
                  reroute: false
                }
            }
          }]
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

output appGatewayId string = appGateway.id
