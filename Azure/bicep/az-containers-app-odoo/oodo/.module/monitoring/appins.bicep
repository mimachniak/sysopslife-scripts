param appInsName string
param logAnalyticsWorkspaceId string
param tags object

resource appInsightsComponents 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appInsName
  location: resourceGroup().location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

output AppInsightKey string = appInsightsComponents.properties.InstrumentationKey
output AppInsightConnectionString string = appInsightsComponents.properties.ConnectionString
