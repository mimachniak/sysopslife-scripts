param par_storage_account_name string

@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param par_storage_account_sku string

@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param par_storage_account_kind string

@allowed( [
  'Cool'
  'Hot'
])
param par_storage_account_accessTier string
param par_tags object
//param stContainerName


resource res_storage_account 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: par_storage_account_name
  location: resourceGroup().location
  tags: par_tags
  properties: {
    accessTier: par_storage_account_accessTier
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true

  }
  sku: {
    name: par_storage_account_sku
  }
  kind: par_storage_account_kind
}

output out_st_accessKey string = listKeys(res_storage_account.id, res_storage_account.apiVersion).keys[0].value
output out_st_apiversion string = res_storage_account.apiVersion
output out_st_id string = res_storage_account.id


