param par_storage_account_name string
param par_storage_account_shares array


@description('Access tier for specific share. GpV2 account can choose between TransactionOptimized (default), Hot, and Cool.')
@allowed([
'Cool'
'Hot'
'Premium'
'TransactionOptimized'
])
param par_storage_account_share_accessTier string = 'Hot'

@description('The authentication protocol that is used for the file share.')
@allowed([
'NFS'
'SMB'
])
param par_storage_account_share_enabledProtocols string = 'SMB'

@description('The maximum size of the share, in gigabytes. Must be greater than 0, and less than or equal to 5TB (5120). For Large File Shares, the maximum size is 102400')
@maxValue(5120)
param par_storage_account_share_shareQuota int = 1024

resource res_storage_account_files 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = [for st_file_name in par_storage_account_shares: {
  name: '${par_storage_account_name}/default/${toLower(st_file_name)}'
  properties: {
    accessTier: par_storage_account_share_accessTier
    enabledProtocols: par_storage_account_share_enabledProtocols
    shareQuota: par_storage_account_share_shareQuota
  }
} ]
