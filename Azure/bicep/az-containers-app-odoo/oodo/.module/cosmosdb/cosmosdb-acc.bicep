
@description('The name of the app to create.')
param par_cosmosdb_name string

@description('Name of the Cosmos DB capability.')
@allowed([
  'EnableServerless'
  'EnableCassandra'
  'EnableTable'
  'EnableGremlin'

])
param par_comosdb_capability string = 'EnableServerless'

@description('The object representing the policy for taking backups on an account.')
param par_comosdb_backup_policy object


@description('Indicates the type of database account. This can only be set at database account creation.')
@allowed([
  'GlobalDocumentDB'
  'MongoDB'
  'Parse'
])
param par_cosmosdb_kind string = 'MongoDB'
param par_location string = resourceGroup().location

param par_cosmosdb_database_name string = ''

param par_cosmosdb_apiproperties object = {
      serverVersion: '4.0'
}

resource res_cosmos_db_account 'Microsoft.DocumentDB/databaseAccounts@2022-02-15-preview' = {
  name: par_cosmosdb_name
  location: par_location
  kind: par_cosmosdb_kind
  properties: {
    backupPolicy: par_comosdb_backup_policy
    consistencyPolicy: {
      defaultConsistencyLevel: 'Eventual'
      maxStalenessPrefix: 1
      maxIntervalInSeconds: 5
    }
    locations: [
      {
        locationName: par_location
        failoverPriority: 0
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: true
    enableFreeTier: false
    capabilities: [
      {
        name: par_comosdb_capability
      }
      {
        name: 'EnableMongo'
      }
      {
        name: 'DisableRateLimitingResponses'
      }
    ]
    apiProperties: par_cosmosdb_apiproperties
  }
}


module mod_cosmosdb_sql_database 'comosdb-mongo.bicep' = if(!empty(par_cosmosdb_database_name)) {
  name: par_cosmosdb_database_name
  params: {
    par_cosmosdb_database_name: par_cosmosdb_database_name
    par_cosmosdb_name: par_cosmosdb_name
  }
  dependsOn: [
    res_cosmos_db_account
  ]
}

output out_comosdb_connectionstring string = res_cosmos_db_account.listConnectionStrings().connectionStrings[0].connectionString
