/*
https://docs.microsoft.com/en-us/azure/container-apps/azure-resource-manager-api-spec?tabs=arm-template
https://docs.microsoft.com/en-us/azure/container-apps/storage-mounts?pivots=aca-arm#container-file-system
https://docs.microsoft.com/en-us/azure/templates/microsoft.app/managedenvironments/storages?tabs=bicep
*/


param par_acapp_environment_name string
param par_acapp_name string
param par_tags object

@description('Bool indicating if app exposes an external http endpoint')
param par_ingress_external bool = true

@description('Target Port in containers for traffic from ingress')
param par_ingress_target_port int = 80

@description('Ingress transport protocol')
@allowed([
  'auto'
  'http'
  'http2'
])
param par_ingress_target_transport string = 'auto'

@description('Bool indicating if HTTP connections to is allowed. If set to false HTTP connections are automatically redirected to HTTPS connections')
param par_ingress_target_allow_in_secure bool = false

param par_continers array 
param par_registries array = []
param par_secrets array = []

param par_acapp_environment_accountName string
param par_acapp_environment_accountKey string
param par_acapp_environment_shareName array = []
param par_acapp_environment_vloumes array = []

param par_min_replicas int = 1
param par_max_replicas int = 1



resource res_log_analytics_workspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: '${par_acapp_environment_name}-log'
  location: resourceGroup().location
  tags: par_tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}


resource res_acapp_environment_name 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: par_acapp_environment_name
  location: resourceGroup().location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: res_log_analytics_workspace.properties.customerId
        sharedKey: listKeys(res_log_analytics_workspace.id, '2020-03-01-preview').primarySharedKey
      }
    }
  }
  dependsOn: [
    res_log_analytics_workspace
  ]
}

resource res_acapp_environment_storage 'Microsoft.App/managedEnvironments/storages@2022-03-01' =  [for st_file_name in par_acapp_environment_shareName: {
  name: '${par_acapp_environment_name}/${st_file_name}'
  properties: {
    azureFile: {
      accountKey: par_acapp_environment_accountKey
      accountName: par_acapp_environment_accountName
      shareName: st_file_name
      accessMode: 'ReadWrite'
    }
  }
  dependsOn: [
    res_acapp_environment_name
  ]
}]

resource res_container_apps 'Microsoft.App/containerApps@2022-03-01' = {
  name: par_acapp_name
  location: resourceGroup().location
  properties: {
    managedEnvironmentId: res_acapp_environment_name.id
    configuration: {
      secrets: par_secrets
      registries: par_registries
      activeRevisionsMode: 'Single'
      ingress: {
        external: par_ingress_external
        targetPort: par_ingress_target_port
        transport: par_ingress_target_transport
        allowInsecure: par_ingress_target_allow_in_secure
      }
    }
    template: {
      containers: par_continers
      scale: {
        minReplicas: par_min_replicas
        maxReplicas: par_max_replicas
      }
      volumes: par_acapp_environment_vloumes
    }
  }
  dependsOn: [
    res_acapp_environment_name
    res_acapp_environment_storage
  ]
}
