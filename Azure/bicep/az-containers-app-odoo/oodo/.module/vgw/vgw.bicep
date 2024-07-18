param par_tags object
param par_vgw_name string
param par_vgw_subnet_id string

@allowed([
  'Vpn'
  'ExpressRoute'
  'LocalGateway'
])
@description('The type of this virtual network gateway.')
param par_vgw_type string = 'Vpn'

@allowed([
  'RouteBased'
  'PolicyBased'
])
@description('The type of this virtual network gateway.')
param par_vgw_vpn_type string = 'RouteBased'

@allowed([
  'Generation1'
  'Generation2'
])
@description('The generation for this VirtualNetworkGateway. Must be None if gatewayType is not VPN.')
param par_vgw_vpn_gateway_generation string = 'Generation1'



@allowed([
  'Basic'
  'ErGw1AZ'
  'ErGw2AZ'
  'ErGw3AZ'
  'HighPerformance'
  'Standard'
  'UltraPerformance'
  'VpnGw1'
  'VpnGw1AZ'
  'VpnGw2'
  'VpnGw2AZ'
  'VpnGw3'
  'VpnGw3AZ'
  'VpnGw4'
  'VpnGw4AZ'
  'VpnGw5'
  'VpnGw5AZ'
])
@description('Gateway SKU name.')
param par_vgw_sku_name string = 'Basic'


@allowed([
  'Basic'
  'ErGw1AZ'
  'ErGw2AZ'
  'ErGw3AZ'
  'HighPerformance'
  'Standard'
  'UltraPerformance'
  'VpnGw1'
  'VpnGw1AZ'
  'VpnGw2'
  'VpnGw2AZ'
  'VpnGw3'
  'VpnGw3AZ'
  'VpnGw4'
  'VpnGw4AZ'
  'VpnGw5'
  'VpnGw5AZ'
])
@description('Gateway SKU tier.')
param par_vgw_sku_tir string = 'Basic'

/// Local Gateway

param par_lgw_name string
param par_lgw_local_address_prefixes array
param par_lgw_ip_address string

// Connection 

param par_vgw_connection_name string

@secure()
param par_connection_shared_key string
/////////////////// Resources ///////////////////////

module mod_pip '../Network/public_ip.bicep'= {
  name: '${par_vgw_name}-PIP'
  params: {
    par_public_ip_name: '${par_vgw_name}-PIP'
    par_tags: par_tags
  }
}


resource res_virtual_network_gateway 'Microsoft.Network/virtualNetworkGateways@2021-08-01' = {
  name: par_vgw_name
  tags: par_tags
  location: resourceGroup().location
  properties: {
    gatewayType: par_vgw_type
    vpnType: par_vgw_vpn_type
    vpnGatewayGeneration: par_vgw_vpn_gateway_generation
    sku: {
      name: par_vgw_sku_name
      tier: par_vgw_sku_tir
    }
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: mod_pip.outputs.out_public_ip_Id
          }
          subnet: {
            id: par_vgw_subnet_id
          }
        }
      }
    ]
  }
  dependsOn: [
    mod_pip
  ]
}

module mod_local_gateway 'lgw.bicep' = {
  name: par_lgw_name
  params: {
    par_lgw_name: par_lgw_name
    par_local_address_prefixes: par_lgw_local_address_prefixes
    par_local_gateway_ip_address: par_lgw_ip_address
    par_tags: par_tags
  }
  dependsOn: [
    res_virtual_network_gateway
  ]
}

module mod_vgw_connection 'vgw-connection.bicep' = {
  name: par_vgw_connection_name
  params: {
    par_connection_shared_key: par_connection_shared_key
    par_lgw_id: mod_local_gateway.outputs.out_lgw_id
    par_tags: par_tags
    par_vgw_connection_name: par_vgw_connection_name
    par_vgw_id: res_virtual_network_gateway.id
  }
  dependsOn: [
    mod_local_gateway
    res_virtual_network_gateway
  ]
}
