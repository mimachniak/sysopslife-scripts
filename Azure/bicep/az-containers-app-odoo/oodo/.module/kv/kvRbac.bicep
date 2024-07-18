param par_key_vault_name string
param par_tags object
param par_enabled_for_deployment bool = false
param par_enabled_for_disk_encryption bool = false // 
param par_enabled_for_template_deployment bool = false
param par_enable_soft_delete bool = false
param par_soft_delete_retention_in_days int = 7


/// Network Parameters 

@allowed([
  'disabled'
  'enabled'
])
param par_public_network_access string = 'enabled'


/// Resources ///

resource res_key_vault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: par_key_vault_name
  location: resourceGroup().location
  tags: par_tags

  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: par_enabled_for_deployment
    enabledForDiskEncryption: par_enabled_for_disk_encryption
    enabledForTemplateDeployment: par_enabled_for_template_deployment
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: par_enable_soft_delete
    tenantId: subscription().tenantId
    softDeleteRetentionInDays: par_soft_delete_retention_in_days
    publicNetworkAccess: par_public_network_access
  }
}

// VNet Integration

param par_subnetid_kv string = ''
param par_private_dns_zone_id_kv string = ''
param par_private_link_integration_kv bool = false

// VNet Integration

module mod_kv_private_link '../Network/private_link_endpoint.bicep' = if (par_private_link_integration_kv  == true) {
  name: '${par_key_vault_name}-PrivateLink'
  params: {
    privateEndpointName: '${par_key_vault_name}-PrivateLink'
    privateLinkServiceConnections: [
      {
        name: '${par_key_vault_name}-PrivateLink'
        properties: {
          privateLinkServiceId: res_key_vault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    subnetid: {
      id: par_subnetid_kv
    }
    tags: par_tags
  }
}

module mod_acr_private_link_dns '../Network/private_link_endpoint_dns.bicep' = if (par_private_link_integration_kv  == true) {
  name: '${par_key_vault_name}-PrivateLink-DNS'
  params: {
    par_private_endpoint_name: mod_kv_private_link.name
    par_private_dns_zone_id: par_private_dns_zone_id_kv
  }
  dependsOn: [
    mod_kv_private_link
  ]
}

output out_kv_uri string = res_key_vault.properties.vaultUri
