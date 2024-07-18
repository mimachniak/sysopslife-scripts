param LoadBalancerName string

resource loadBalancerExternal 'Microsoft.Network/loadBalancers@2020-11-01' = {
  name: LoadBalancerName
  location: resourceGroup().location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerNameFrontEnd'
        properties: {
          publicIPAddress: {
            id: 'publicIPAddresses.id'
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'name'
      }
    ]
    inboundNatRules: [
      {
        name: 'inboundAks'
        properties: {
          frontendIPConfiguration: {
            id: 'frontendIPConfiguration.id'
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          enableFloatingIP: false
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'outBoundAks'
        properties: {
          frontendIPConfiguration: {
             id: 'frontendIPConfiguration.id'
          }
          backendAddressPool: {
            id: 'backendAddressPool.id'
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: 'probe.id'
          }
        }
      }
    ]
    probes: [
      {
        name: 'name'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}
