@description('The name of the app to create.')
param par_postgre_sql_name string

@description('Local administrator login.')
param par_administrator_login string

@description('Local administrator login password.')
@secure()
param par_administrator_login_password string

@description('Azure Active Directory administrator login - group or user.')
param par_aad_admin_login string

@description('Azure Active Directory administrator login object id - group or user.')
param par_aad_admin_login_object_id string

@description('Azure Active Directory tenant ID.')
param par_aad_tenant_id string 
param par_tags object

@description('The version of a server.')
@allowed([
  '10'
  '10.0'
  '10.2'
  '11'
  '9.5'
  '9.6'
])
param par_postgre_sql_ver string


@description('Enforce a minimal Tls version for the server.')
@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
  'TLSEnforcementDisabled' 
])
param par_minimal_tls_version string = 'TLS1_2'

@description('par_ssl_enforcement')
@allowed([
  'Disabled'
  'Enabled'
])
param par_ssl_enforcement string = 'Enabled'

@description('Backup retention days for the server.')
param par_backup_retention_days int = 7

@description('Backup retention days for the server.')
@allowed([
  'Disabled'
  'Enabled'
])
param par_geo_redundant_backup string = 'Disabled'

@description('Enable Storage Auto Grow.')
@allowed([
  'Disabled'
  'Enabled'
])
param par_storage_autogrow string = 'Disabled'

@description('Max storage allowed for a server.')
param par_storage_MB int = 51200

// SKU 
@description('The name of the sku, typically, tier + family + cores, e.g. B_Gen4_1, GP_Gen5_8.')
param par_postgre_sql_sku_name string = 'B_Gen5_2'

@description('The tier of the particular SKU, e.g. Basic.')
@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized' 
])
param par_postgre_sql_sku_tier string = 'Basic'

@description('The scale up/out capacity, representing servers compute units.')
param par_postgre_sql_sku_capacity int = 2

@description('The scale up/out capacity, representing servers compute units.')
param par_postgre_sql_sku_size string = '51200'

@description('The family of hardware.')
param par_postgre_sql_sku_family string = 'Gen5'

// VNet Integration

param par_subnetid_postgre_sql string = ''
param par_private_dns_zone_id_postgre_sql string = ''
param par_psql_private_link_integration bool = false


/// Resources ///

resource res_postgre_sql 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: par_postgre_sql_name
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    capacity: par_postgre_sql_sku_capacity
    family: par_postgre_sql_sku_family
    name: par_postgre_sql_sku_name
    size: par_postgre_sql_sku_size
    tier: par_postgre_sql_sku_tier
  }
  properties: {
    version: par_postgre_sql_ver
    createMode: 'Default'
    administratorLogin: par_administrator_login
    administratorLoginPassword: par_administrator_login_password
    minimalTlsVersion: par_minimal_tls_version
    sslEnforcement: par_ssl_enforcement
    storageProfile: {
      backupRetentionDays: par_backup_retention_days
      geoRedundantBackup: par_geo_redundant_backup
      storageAutogrow: par_storage_autogrow
      storageMB: par_storage_MB
    }

  }
  location: resourceGroup().location
  tags: par_tags
}

resource res_postgre_sql_admin 'Microsoft.DBforPostgreSQL/servers/administrators@2017-12-01' = {
  name: '${par_postgre_sql_name}/ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: par_aad_admin_login
    sid: par_aad_admin_login_object_id
    tenantId: par_aad_tenant_id
  }
  dependsOn: [
    res_postgre_sql
  ]
}

// VNet Integration

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

module mod_acr_private_link_dns '../Network/private_link_endpoint_dns.bicep' = if (par_psql_private_link_integration  == true) {
  name: '${par_postgre_sql_name}-PrivateLink-DNS'
  params: {
    par_private_endpoint_name: mod_psql_private_link.name
    par_private_dns_zone_id: par_private_dns_zone_id_postgre_sql
  }
  dependsOn: [
    mod_psql_private_link
  ]
}

output out_postgre_sql_id string = res_postgre_sql.id
