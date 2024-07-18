@description('Azure Server name.')
param par_mysql_server_name string

@description('Max storage allowed for a server.')
param par_mysql_storage_size_mb int = 32768

@description('Enable Storage Auto Grow.')
@allowed([
  'Disabled'
  'Enabled'
])
param par_mysql_storage_auto_grow string = 'Enabled'

@description('Backup retention days for the server.')
param par_mysql_backup_retention_days int = 7

@description('Enable Geo-redundant or not for server backup.')
@allowed([
  'Disabled'
  'Enabled'
])
param par_mysql_backup_geo_redundant string = 'Disabled'

@description('Enable ssl enforcement or not when connect to server.')
@allowed([
  'Disabled'
  'Enabled'
])
param par_mysql_ssl_enforcement string = 'Enabled'

@description('Enforce a minimal Tls version for the server.')
@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
  'TLSEnforcementDisabled'
])
param par_mysql_minimal_tls_version string = 'TLS1_2'

@description('The version of a server.')
@allowed([
  '5.6'
  '5.7'
  '8.0'
])
param par_mysql_server_version string = '5.7'

@description('The name of the sku, typically, tier + family + cores, e.g. B_Gen4_1, GP_Gen5_8.')
param par_mysql_vmName string = 'B_Gen5_1'

@description('The tier of the particular SKU, e.g. Basic.')
@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
param par_mysql_server_edition string =  'Basic'

@description('The scale up/out capacity, representing servers compute units.')
param par_mysql_vcores int = 1

@description('The family of hardware.')
param par_mysql_sku_family string = 'Gen5'

@description('The size code, to be interpreted by resource as appropriate.')
param par_mysql_sku_size_mb string = '32768'

@description('The administrators login name of a server. Can only be specified when the server is being created and is required for creation. The login name is required when updating password.')
param par_mysql_collation_server_user_name string = 'admsql'

@description('The password of the administrator login.')
@secure()
param par_mysql_collation_server_user_password string

@description('The server administrator login account name.')
param par_mysql_aad_administrator_login string = ''

@description('The server administrator Sid (Secure ID).')
param par_mysql_aad_administrator_sid string = ''


// DataBase Settings

param par_mysql_db_charset string = 'utf8'
param par_mysql_db_collation string = 'utf8_general_ci'
param par_mysql_db_collation_database_name string

// Firewall Settings

@description('Configures the servers firewall to accept connections from all Azure resources, including resources not in your subscription.')
param par_mysql_allow_azure_services bool = false




resource res_mysql_server 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  name: par_mysql_server_name
  location: resourceGroup().location
  properties: {
    createMode: 'Default'
    administratorLogin: par_mysql_collation_server_user_name
    administratorLoginPassword: par_mysql_collation_server_user_password
    storageProfile: {
      storageMB: par_mysql_storage_size_mb
      backupRetentionDays: par_mysql_backup_retention_days
      geoRedundantBackup: par_mysql_backup_geo_redundant
      storageAutogrow: par_mysql_storage_auto_grow
    }
    sslEnforcement: par_mysql_ssl_enforcement
    version: par_mysql_server_version
    minimalTlsVersion: par_mysql_minimal_tls_version
    
  }
  sku: {
    name: par_mysql_vmName
    tier: par_mysql_server_edition
    capacity: par_mysql_vcores
    size: par_mysql_sku_size_mb
    family: par_mysql_sku_family
  }
}

resource res_mysql_server_database 'Microsoft.DBforMySQL/servers/databases@2017-12-01' = if (!empty(par_mysql_db_collation_database_name)) {
  name: '${par_mysql_server_name}/${par_mysql_db_collation_database_name}'
  properties: {
    charset: par_mysql_db_charset
    collation: par_mysql_db_collation
  }
  dependsOn: [
    res_mysql_server
  ]
}

resource res_mysql_server_firewall_AllowAllWindowsAzureIps 'Microsoft.DBforMySQL/servers/firewallRules@2017-12-01' = if (par_mysql_allow_azure_services == true) {
  name: '${par_mysql_server_name}/AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
  dependsOn: [
    res_mysql_server
  ]
}


resource res_mysql_server_administrators 'Microsoft.DBforMySQL/servers/administrators@2017-12-01' = if (!empty(par_mysql_aad_administrator_login)) {
  name: '${par_mysql_server_name}/activeDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: par_mysql_aad_administrator_login
    sid: par_mysql_aad_administrator_sid
    tenantId: subscription().tenantId
  }
  dependsOn: [
    res_mysql_server
  ]
}
