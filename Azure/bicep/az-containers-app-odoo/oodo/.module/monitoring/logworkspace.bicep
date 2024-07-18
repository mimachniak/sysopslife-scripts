param par_log_analytics_name string
param par_tags object

resource res_log_analytics_workspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: par_log_analytics_name
  location: resourceGroup().location
  tags: par_tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 120
  }
}

output log_analytics_id string = res_log_analytics_workspace.id
output log_analytics_customer_id string = res_log_analytics_workspace.properties.customerId
