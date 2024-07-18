
@description('The name of the app to create.')
param par_cosmosdb_database_name string

param par_cosmosdb_name string

resource res_documentdb_sqldatabases 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-02-15-preview' = {
  name: '${par_cosmosdb_name}/${par_cosmosdb_database_name}'
  properties: {
    resource: {
      id: par_cosmosdb_database_name
    }
  }
}
