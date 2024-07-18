param par_vnet_peering_name string
param par_vnet_name string
param par_vnet_remote_network_id string
param par_vnet_remote_address_space array
param par_vnet_allow_forwarded_traffic bool = true
param par_vnet_allow_gateway_transit bool = false
param par_vnet_allow_virtual_network_access bool = true
param par_vnet_doNot_verify_remote_gateways bool = true
param par_vnet_use_remote_gateways bool = false



resource vnet_peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: '${par_vnet_name}/${par_vnet_peering_name}'
  properties: {
    allowForwardedTraffic: par_vnet_allow_forwarded_traffic
    allowGatewayTransit: par_vnet_allow_gateway_transit
    allowVirtualNetworkAccess: par_vnet_allow_virtual_network_access
    doNotVerifyRemoteGateways: par_vnet_doNot_verify_remote_gateways
    useRemoteGateways: par_vnet_use_remote_gateways
    remoteAddressSpace: {
      addressPrefixes: par_vnet_remote_address_space
    }
    remoteVirtualNetwork: {
      id: par_vnet_remote_network_id
    }
  }
}
