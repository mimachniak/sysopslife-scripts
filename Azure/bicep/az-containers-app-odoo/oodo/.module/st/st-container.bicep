param par_storage_account_name string
param par_storage_account_containers array
@allowed([
'Blob'
'Container'
'None'
])
param par_storage_account_publicAccess string = 'Container'

resource stContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = [for st_container_name in par_storage_account_containers: {
  name: '${par_storage_account_name}/default/${toLower(st_container_name)}'
  properties: {
    publicAccess: par_storage_account_publicAccess
  }
} ]

