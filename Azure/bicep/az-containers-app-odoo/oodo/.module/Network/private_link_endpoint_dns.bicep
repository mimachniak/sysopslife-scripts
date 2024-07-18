param par_private_endpoint_name string
param par_private_dns_zone_id string

resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${par_private_endpoint_name}/dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: par_private_dns_zone_id
        }
      }
    ]

  }
}
