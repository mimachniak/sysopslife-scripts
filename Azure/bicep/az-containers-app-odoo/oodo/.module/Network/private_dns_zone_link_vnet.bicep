param par_private_dns_zone_name string
param par_vnet_id string

resource private_dns_zone_link_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${par_private_dns_zone_name}/${par_private_dns_zone_name}-link-vnet'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: par_vnet_id
    }
  }
}
