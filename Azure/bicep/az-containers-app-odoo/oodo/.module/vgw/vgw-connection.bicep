param par_vgw_connection_name string
param par_tags object

@allowed([
  'ExpressRoute'
  'IPsec'
  'VPNClient'
  'Vnet2Vnet'
])
@description('Gateway connection type.')
param par_vgw_connection_type string = 'IPsec'

@allowed([
  'IKEv1'
  'IKEv2'
])
@description('Gateway connection protocol.')
param par_vgw_connection_protocol string = 'IKEv2'

param par_vgw_id string
param par_lgw_id string


@secure()
@description('The IPSec shared key.')
param par_connection_shared_key string

//// Resources


resource res_vgw_connection 'Microsoft.Network/connections@2021-08-01' = {
  name: par_vgw_connection_name
  tags: par_tags
  location: resourceGroup().location
  properties: {
    connectionType: par_vgw_connection_type
    connectionProtocol: par_vgw_connection_protocol
    routingWeight: 0
    virtualNetworkGateway1: {
      id: par_vgw_id
      properties: {
        
      }
    }
    localNetworkGateway2: {
      id: par_lgw_id
      properties: {
      }
    }
    sharedKey: par_connection_shared_key
    enableBgp: false
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
    ipsecPolicies: []
    trafficSelectorPolicies: []
    expressRouteGatewayBypass: false
    dpdTimeoutSeconds: 0
    connectionMode: 'Default'
  }
}
