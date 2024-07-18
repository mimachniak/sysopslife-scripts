
targetScope = 'subscription'

// Parameters

// Parameters section //

//@description('The location in which all resources should be deployed.')
//param location string = 'WestEurope'

@allowed([
  'D'
  'T'
  'S'
  'U'
  'P'
  'G'
])
@description('Environment code base on table.Max characters is 1.')
param par_env_prefix string = 'D'

@maxLength(3)
@description('Short name of Azure region base on code table. Max characters is 3.')
param par_location_prefix string = 'WEu'

@maxLength(2)
@description('The Instance number. Max digits is 2.')
param par_instance_number string = substring((uniqueString(subscription().id)),0,2)

param par_base_name string = substring((subscription().subscriptionId),0,4)

param par_tags object = {
  Environment: par_env_prefix
}

// Net 

@description('Required. An Array of 1 or more IP Address Prefixes for the Virtual Network.')
param par_vnet_address_space object

@description('Optional. An Array of subnets to deploy to the Virtual Network.')
param par_vnet_subnets array

//PostGres

param par_pgsql_administrator_login string = 'sqladm'

@secure()
param par_pgsql_administrator_login_password string

// ACI 

param par_st_kind_odoo string = 'StorageV2'
param par_st_sku_odoo string = 'Standard_RAGRS'
param par_st_accessTier_odoo string = 'Hot'

param par_st_shares_odoo array = [
  'extra-addons'
  'data-dir'
  'odoo-log'
]

param par_image_name string = 'dmctacr.azurecr.io/odoo:dev-latest'
param par_image_registry_login_server string = 'dmctacr.azurecr.io'
param par_image_registry_username string = 'dmctacr'

@secure()
param par_image_registry_password string

//// Variable ////

var var_rg_name_pgsql = '${par_env_prefix}-${par_base_name}-${par_location_prefix}-PGSQL-RG${par_instance_number}'
var var_rg_name_net = '${par_env_prefix}-${par_base_name}-${par_location_prefix}-NET-RG${par_instance_number}'
var var_rg_name_app_oodo = '${par_env_prefix}-${par_base_name}-${par_location_prefix}-APP-RG${par_instance_number}'

var var_pgsql_name = toLower('${par_env_prefix}-${par_base_name}-${par_location_prefix}-PGSQL${par_instance_number}')
var var_vnet = '${par_env_prefix}-${par_base_name}-${par_location_prefix}-VNET${par_instance_number}'


var var_st_name_odoo = toLower('${par_env_prefix}${par_base_name}${par_location_prefix}ST${par_instance_number}15')

var var_aci_name_oodo = toLower('${par_env_prefix}-${par_base_name}-${par_location_prefix}-ACI${par_instance_number}')
var var_acapp_name_oodo = toLower('${par_env_prefix}-${par_base_name}-${par_location_prefix}-ACAPP${par_instance_number}')



/////////////////////////////// Rsources ////////////////////////////////////////


/////////// Resource Groups /////////

module mod_rg_pgsql '.module/resource-group/rg.bicep' = {
  name: var_rg_name_pgsql
  params: {
    par_tags: par_tags
    pra_rg_name: var_rg_name_pgsql
  }
}

module mod_rg_net '.module/resource-group/rg.bicep' = {
  name: var_rg_name_net
  params: {
    par_tags: par_tags
    pra_rg_name: var_rg_name_net
  }
}

module mod_rg_app_oodo '.module/resource-group/rg.bicep' = {
  name: var_rg_name_app_oodo
  params: {
    par_tags: par_tags
    pra_rg_name: var_rg_name_app_oodo
  }
}

/////////// Network /////////

module mod_vnet_product '.module/Network/vnet.bicep' = {
  scope: resourceGroup(mod_rg_net.name)
  name: var_vnet
  params: {
    par_tags: par_tags
    par_vnet_name: var_vnet
    par_vnet_address_space: par_vnet_address_space
    par_vnet_subnets: par_vnet_subnets
  }
  dependsOn: [
    mod_rg_net
  ]
}


/////////// PostGres SQL /////////


module mod_pgsql '.module/db/PostgreSQL-flexible.bicep' = {
  scope: resourceGroup(var_rg_name_pgsql)
  name: var_pgsql_name
  params: {
    par_administrator_login: par_pgsql_administrator_login
    par_administrator_login_password:par_pgsql_administrator_login_password
    par_postgre_sql_name: var_pgsql_name
    par_postgre_sql_ver: '13'
    par_tags: par_tags
  }
  dependsOn: [
    mod_rg_pgsql
  ]
}

/////////// Storage account /////////

module mod_st_odoo '.module/st/st.bicep' = {
  scope: resourceGroup(var_rg_name_app_oodo)
  name: var_st_name_odoo
  params: {
    par_storage_account_accessTier: par_st_accessTier_odoo
    par_storage_account_kind: par_st_kind_odoo
    par_storage_account_name: var_st_name_odoo
    par_storage_account_sku: par_st_sku_odoo
    par_tags: par_tags
  }
  dependsOn: [
    mod_rg_app_oodo
  ]
}


module mod_st_shares_odoo '.module/st/st-azurefiles.bicep' = {
  scope: resourceGroup(var_rg_name_app_oodo)
  name: 'fileShares'
  params: {
    par_storage_account_name: var_st_name_odoo
    par_storage_account_shares: par_st_shares_odoo
  }
  dependsOn: [
    mod_st_odoo
  ]
}

/////////// Oodo ACI /////////
/*
var var_aci_env = [

  {
    name: 'HOST'
    secureValue: null
    value: mod_pgsql.outputs.fully_qualified_domain_name
  }
  {
    name: 'USER'
    secureValue: null
    value: mod_pgsql.outputs.administrator_login
  }
  {
    name: 'PASSWORD'
    secureValue: null
    value: par_pgsql_administrator_login_password
  }


]
var var_volumes = [
  {
    name: 'extra-addons'
    azureFile: {
        shareName: 'extra-addons'
        storageAccountName: var_st_name_odoo
        storageAccountKey: mod_st_odoo.outputs.out_st_accessKey
    }
  }
  {
    name: 'lib'
    azureFile: {
        shareName: 'lib'
        storageAccountName: var_st_name_odoo
        storageAccountKey: mod_st_odoo.outputs.out_st_accessKey
    }
  }
]

var var_volume_mounts = [
  {
    name: 'extra-addons'
    mountPath: '/mnt/extra-addons'
  }
  {
    name: 'lib'
    mountPath: '/mnt/lib'
  }

]

var var_image_registry_credentials = [
  {
    server: par_image_registry_login_server
    username: par_image_registry_username
    password: par_image_registry_password
  }

]

module mod_aci_odoo '.module/aci/aci.bicep' = {
  scope: resourceGroup(var_rg_name_app_oodo)
  name: var_aci_name_oodo
  params: {
    par_environment_variables: var_aci_env
    par_volumes: var_volumes
    par_volume_mounts: var_volume_mounts
    par_image_registry_credentials: var_image_registry_credentials
    par_image: par_image_name
    par_port: 8069
    par_cpu_cores: 2
    par_memory_in_gb: 4
    par_tags: par_tags
  }
  dependsOn: [
    mod_pgsql
    mod_st_shares_odoo
  ]
}
*/
//// Contianer Apps ///

var var_acapp_registries = [
  {
    passwordSecretRef: 'container-registry-password'
    server: par_image_registry_login_server
    username: par_image_registry_username
  }
]

var var_acapp_secrets = [
  {
    name: 'container-registry-password'
    value: par_image_registry_password
  }
  {
    name: 'pgsql-password'
    value: par_pgsql_administrator_login_password
  }
]

var var_acapp_containers = [

  {
    // image: 'doddodev.azurecr.io/odoo:dev-latest'
    image: par_image_name
    name: 'odoo'
    resources: {
      cpu: 2
      memory: '4Gi'
    }
    volumeMounts: [
      {
        volumeName: 'azure-files-lib'
        mountPath: 'mnt/data-dir'
      }
      {
        volumeName: 'azure-files-extra-addons'
        mountPath: 'mnt/extra-addons'
      }
      {
        volumeName: 'azure-files-log'
        mountPath: 'mnt/odoo-log'
      }
    ]
    env: [
      {
        name: 'HOST'
        value: mod_pgsql.outputs.fully_qualified_domain_name
      }
      {
        name: 'PASSWORD'
        secretRef: 'pgsql-password'
      }
      {
        name: 'USER'
        value: mod_pgsql.outputs.administrator_login
      }
    ]
  }

]

var var_acapp_volumes = [
  {
    name: 'azure-files-lib'
    storageType: 'AzureFile'
    storageName: 'data-dir'
  }
  {
    name: 'azure-files-extra-addons'
    storageType: 'AzureFile'
    storageName: 'extra-addons'
  }
  {
    name: 'azure-files-log'
    storageType: 'AzureFile'
    storageName: 'odoo-log'
  }
]

module mod_acapp_odoo '.module/acapp/acapp.bicep' = {
  scope: resourceGroup(var_rg_name_app_oodo)
  name: var_acapp_name_oodo
  params: {
    par_acapp_environment_name: '${var_acapp_name_oodo}-ENV'
    par_acapp_name: var_acapp_name_oodo
    par_continers: var_acapp_containers
    par_registries: var_acapp_registries
    par_tags: par_tags
    par_ingress_target_port: 8069
    par_secrets: var_acapp_secrets
    par_acapp_environment_accountKey: mod_st_odoo.outputs.out_st_accessKey
    par_acapp_environment_accountName: mod_st_odoo.name
    par_acapp_environment_shareName: par_st_shares_odoo
    par_acapp_environment_vloumes: var_acapp_volumes
  }
  dependsOn: [
    mod_pgsql
    mod_st_shares_odoo
  ]
}

/////////////////////////////// Outputs ////////////////////////////////////////


