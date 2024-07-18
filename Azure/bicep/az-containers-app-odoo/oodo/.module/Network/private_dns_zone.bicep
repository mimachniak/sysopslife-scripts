param par_private_dns_zone_name string
param par_tags object
param par_vnet_id string = ''

resource res_private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: par_private_dns_zone_name
  location: 'global'
  tags: par_tags
}

module mod_private_dns_zone_link_vnet 'private_dns_zone_link_vnet.bicep' = if (!empty(par_vnet_id)) {
  name: '${par_private_dns_zone_name}-link-vnet'
  params: {
    par_private_dns_zone_name: par_private_dns_zone_name
    par_vnet_id: par_vnet_id
  }
  dependsOn: [
    res_private_dns_zone
  ]
}

output out_private_dns_zone_name string = res_private_dns_zone.name
output out_private_dns_zone_Id string = res_private_dns_zone.id
