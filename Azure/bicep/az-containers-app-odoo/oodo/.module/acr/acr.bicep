param par_acr_name string
param par_tags object
param par_subnetid string = ''
param par_private_dns_zone_id string = ''

@allowed([
  'Basic'
  'Classic'
  'Premium'
  'Standard'
])
param par_acr_sku string = 'Premium'

resource res_azure_container_registry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: par_acr_name
  tags: par_tags
  location: resourceGroup().location
  sku: {
    name: par_acr_sku
  }
  properties: {
    adminUserEnabled: true
  }
}

module mod_acr_private_link '../Network/private_link_endpoint.bicep' = if (par_acr_sku  == 'Premium') {
  name: '${par_acr_name}-PrivateLink'
  params: {
    privateEndpointName: '${par_acr_name}-PrivateLink'
    privateLinkServiceConnections: [
      {
        name: '${par_acr_name}-PrivateLink'
        properties: {
          privateLinkServiceId: res_azure_container_registry.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
    subnetid: {
      id: par_subnetid
    }
    tags: par_tags
  }
  dependsOn: [
    res_azure_container_registry
  ]
}

module mod_acr_private_link_dns '../Network/private_link_endpoint_dns.bicep' = if (par_acr_sku  == 'Premium') {
  name: '${par_acr_name}-PrivateLink-DNS'
  params: {
    par_private_endpoint_name: mod_acr_private_link.name
    par_private_dns_zone_id: par_private_dns_zone_id
  }
  dependsOn: [
    mod_acr_private_link
  ]
}

output out_acr_id string = res_azure_container_registry.id
output out_acr_admin_password string = res_azure_container_registry.listCredentials().passwords[0].value
