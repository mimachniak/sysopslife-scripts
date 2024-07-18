param par_tags object
param par_lgw_name string
param par_local_gateway_ip_address string
param par_local_address_prefixes array

resource res_local_network_gateway  'Microsoft.Network/localNetworkGateways@2021-08-01' = {
  name: par_lgw_name
  tags: par_tags
  location: resourceGroup().location
  properties: {
    gatewayIpAddress: par_local_gateway_ip_address
    localNetworkAddressSpace: {
      addressPrefixes: par_local_address_prefixes
    }
  }
}


output out_lgw_id string = res_local_network_gateway.id
