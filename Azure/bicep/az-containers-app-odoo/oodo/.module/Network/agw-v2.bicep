param tags object
param basename string
param appGwSubnetId string
param ApplicationGatewaySku object

module appGwPIP 'publicip.bicep' = {
  name: 'appGwPIP'
  params: {
    publicipName: '${basename}-PIP'
    publicipproperties: {
      publicIPAllocationMethod: 'Static' 
    }
    publicipsku: {
      name: 'Standard'
      tier: 'Regional'
    }
    tags: tags
  }
}

resource appGw 'Microsoft.Network/applicationGateways@2021-02-01'  = {
  name: basename
  location: resourceGroup().location
  tags: tags
  properties: {
    sku: ApplicationGatewaySku
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGwSubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGwPIP.outputs.publicipId
          }
        }
      }
    ]
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 2
    }
  frontendPorts: [
    {
      name: 'port_80'
      properties: {
          port: 80
      }
    }
    ]
  backendAddressPools: [
      {
          name: 'tempBackend'
          properties: {
              backendAddresses: []
          }
      }
    ]
  backendHttpSettingsCollection: [
      {
          name: 'tempHttpSettings'
          properties: {
              port: 80
              protocol: 'Http'
              cookieBasedAffinity: 'Disabled'
              pickHostNameFromBackendAddress: false
              affinityCookieName: 'ApplicationGatewayAffinity'
              requestTimeout: 20
          }
      }
  ]
  httpListeners: [
      {
          name: 'HttpListener'
          properties: {
              frontendIPConfiguration: {
                  id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', basename, 'appGwPublicFrontendIp')
                  //[concat(resourceId('Microsoft.Network/applicationGateways', parameters('applicationGateways_Dev_ToRemove_name')), '/frontendIPConfigurations/appGwPublicFrontendIp')]
              }
              frontendPort: {
                  id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', basename, 'port_80')
                  //[concat(resourceId('Microsoft.Network/applicationGateways', parameters('applicationGateways_Dev_ToRemove_name')), '/frontendPorts/port_80')]
              }
              protocol: 'Http'
              hostNames: []
              requireServerNameIndication: false
          }
      }
    ]
    requestRoutingRules: [
      {
          name: 'tempHTTPRule'
          properties: {
              ruleType: 'Basic'
              httpListener: {
                  id: resourceId('Microsoft.Network/applicationGateways/httpListeners', basename, 'HttpListener')
              }
              backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', basename, 'tempBackend')
              }
              backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', basename, 'tempHttpSettings')
              }
          }
      }
    ]
  } // End of properites
  
}

output appGwId string = appGw.id
