@description('The name of the app to create.')
param par_postgre_sql_name string

@description('Local administrator login.')
param par_administrator_login string = 'admdb'

@description('Local administrator login password.')
@secure()
param par_administrator_login_password string

@description('Azure Active Directory administrator login - group or user.')
param par_aad_admin_login string = ''

@description('Azure Active Directory administrator login object id - group or user.')
param par_aad_admin_login_object_id string = ''

@description('Azure Active Directory tenant ID.')
param par_aad_tenant_id string = ''

param par_tags object

@description('The version of a server.')
@allowed([
  '10'
  '11'
  '12'
  '13'
  '14'
])
param par_postgre_sql_ver string

@description('Backup retention days for the server.')
param par_backup_retention_days int = 7

@description('Backup retention days for the server.')
@allowed([
  'Disabled'
  'Enabled'
])
param par_geo_redundant_backup string = 'Disabled'


// SKU 
@description('The name of the sku, typically, tier + family + cores, e.g. B_Gen4_1, GP_Gen5_8.')
@allowed([
'Standard_B1ms'
'Standard_B1s'
'Standard_B2s'
'Standard_D16s_v3'
'Standard_D2s_v3'
'Standard_D32s_v3'
'Standard_D4s_v3'
'Standard_D64s_v3'
'Standard_D8s_v3'
'Standard_E16s_v3'
'Standard_E2s_v3'
'Standard_E32s_v3'
'Standard_E4s_v3'
'Standard_E64s_v3'
'Standard_E8s_v3'
'Standard_M128ms'
'Standard_M128s'
'Standard_M64ms'
'Standard_M64s'
'Standard_E48s_v3'
'Standard_D2ds_v4'
'Standard_D4ds_v4'
'Standard_D8ds_v4'
'Standard_D16ds_v4'
'Standard_D32ds_v4'
'Standard_D48ds_v4'
'Standard_D64ds_v4'
'Standard_E2ds_v4'
'Standard_E4ds_v4'
'Standard_E8ds_v4'
'Standard_E16ds_v4'
'Standard_E32ds_v4'
'Standard_E48ds_v4'
'Standard_E64ds_v4'
'Standard_D48s_v3'
'Standard_E20ds_v4'
'Standard_M8ms'
'Standard_M16ms'
'Standard_M32ts'
'Standard_M32ls'
'Standard_M32ms'
'Standard_M64ls'
'Standard_M64'
'Standard_M64m'
'Standard_M128'
'Standard_M128m'
])
param par_sku_name string = 'Standard_B1ms'


@description('The tier of the particular SKU. Burstable - dont support HA')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized' 
])
param par_sku_tier string = 'Burstable'

@description('Max storage allowed for a server. Min 32 GB ')
@minValue(32)
@maxValue(16384)
param par_storage_gb int = 32

@description('The HA mode for the server.')
@allowed([
  'Disabled'
  'ZoneRedundant'
])
param par_ha_mode string = 'Disabled'

@description('availability zone information of the standby.')
@allowed([
  'ZoneRedundant'
  'SameZone'
])
param par_ha_standby_availability_zone string = 'SameZone'

@description('Availability zone information of the server.')
param par_availability_zone string = '1'


param par_allow_all_azure_services bool = true

// VNet Integration

param par_subnetid_postgre_sql string = ''
param par_private_dns_zone_id_postgre_sql string = ''
param par_psql_private_link_integration bool = false
param virtualNetworkExternalId string = ''
param privateDnsZoneArmResourceId string = ''
param subnetName string = ''


/// Resources ///

resource res_postgre_sql 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  name: par_postgre_sql_name
  sku: {
    name: par_sku_name
    tier: par_sku_tier
  }
  properties: {
    version: par_postgre_sql_ver
    administratorLogin: par_administrator_login
    administratorLoginPassword: par_administrator_login_password
    availabilityZone: par_availability_zone
    network: {
        delegatedSubnetResourceId: (empty(virtualNetworkExternalId) ? json('null') : json('${virtualNetworkExternalId}/subnets/${subnetName}'))
        privateDnsZoneArmResourceId: (empty(virtualNetworkExternalId) ? json('null') : privateDnsZoneArmResourceId)
    }
    backup: {
      backupRetentionDays: par_backup_retention_days
      geoRedundantBackup: par_geo_redundant_backup
    }
   highAvailability: {
      mode: (par_sku_tier == 'Burstable') ? 'Disabled' : par_ha_mode
      standbyAvailabilityZone: (par_ha_mode == 'Disabled') ? json('null') : par_ha_standby_availability_zone
    }
    storage: {
      storageSizeGB: par_storage_gb
    }
  }
  location: resourceGroup().location
  tags: par_tags
}


resource res_postgre_sql_firewall_allow_all 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2021-06-01' = if (par_allow_all_azure_services == true ) {
  name: '${par_postgre_sql_name}/AllowAllAzureServicesAndResourcesWithinAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
  dependsOn: [
    res_postgre_sql
  ]
}


///////////////// Outputs ////////////////////

output administrator_login string = res_postgre_sql.properties.administratorLogin
output fully_qualified_domain_name string = res_postgre_sql.properties.fullyQualifiedDomainName

// resource res_pgsql_administratora 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2021-06-01' = {
//   name: 
// }
// Administrators



// Private link
/*
module mod_psql_private_link '../Network/private_link_endpoint.bicep' = if (par_psql_private_link_integration  == true) {
  name: '${par_postgre_sql_name}-PrivateLink'
  params: {
    privateEndpointName: '${par_postgre_sql_name}-PrivateLink'
    privateLinkServiceConnections: [
      {
        name: '${par_postgre_sql_name}-PrivateLink'
        properties: {
          privateLinkServiceId: res_postgre_sql.id
          groupIds: [
            'postgresqlServer'
          ]
        }
      }
    ]
    subnetid: {
      id: par_subnetid_postgre_sql
    }
    tags: par_tags
  }
}
output out_postgre_sql_id string = res_postgre_sql.id
*/
