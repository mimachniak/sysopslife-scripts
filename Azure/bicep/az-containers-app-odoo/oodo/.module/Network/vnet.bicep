@description('Required. An Array of 1 or more IP Address Prefixes for the Virtual Network.')
param par_vnet_address_space object = {
  addressPrefixes: [
    '10.0.0.0/16'
  ]
}

@description('Required. The Virtual Network (vNet) Name.')
param par_vnet_name string

@description('Optional. An Array of subnets to deploy to the Virtual Network.')
param par_vnet_subnets array = []

@description('Optional. DNS Servers associated to the Virtual Network.')
param par_dns_servers array = []


param par_tags object

resource res_vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: par_vnet_name
  location: resourceGroup().location
  tags: par_tags
  properties: {
    addressSpace: par_vnet_address_space
    subnets: par_vnet_subnets
    dhcpOptions: {
      dnsServers: par_dns_servers
    }
  }
}

output out_vnet_id string = res_vnet.id
output out_vnet_name string = res_vnet.name
output out_vnet_subnets array = res_vnet.properties.subnets
