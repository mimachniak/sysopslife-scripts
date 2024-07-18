
param par_st_name string

@allowed([
  true
  false
])
param par_st_blobservices_change_feed_enabled bool = false

@allowed([
  true
  false
])
param par_st_blobservices_restore_policy_enabled bool = false

@allowed([
  true
  false
])
param par_st_blobservices_delete_retention_policy_enabled bool = true
param par_st_blobservices_delete_retention_policy_days int = 7

@allowed([
  true
  false
])
param par_st_blobservices_retention_policy_allow_permanent_delete bool = false

@allowed([
  true
  false
])
param par_st_blobservices_retention_policy_enabled bool = true
param par_st_blobservices_retention_policy_days int = 7

@allowed([
  true
  false
])
param par_st_blobservices_is_versioning_enabled bool = true
param par_st_blobservices_cors_rules array = []

resource res_st_blob_services 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name: '${par_st_name}/default'
  properties: {
    changeFeed: {
      enabled: par_st_blobservices_change_feed_enabled
    }
    restorePolicy: {
      enabled: par_st_blobservices_restore_policy_enabled
    }
    containerDeleteRetentionPolicy: {
      enabled: par_st_blobservices_delete_retention_policy_enabled
      days: par_st_blobservices_delete_retention_policy_days
    }
    cors: {
      corsRules: par_st_blobservices_cors_rules
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: par_st_blobservices_retention_policy_allow_permanent_delete
      enabled: par_st_blobservices_retention_policy_enabled
      days: par_st_blobservices_retention_policy_days
    }
    isVersioningEnabled: par_st_blobservices_is_versioning_enabled
  }

}
