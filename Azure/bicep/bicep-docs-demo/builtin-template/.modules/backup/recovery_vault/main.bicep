/*
SUMMARY: Recovery Services Vault
DESCRIPTION: Deploys a Recovery Services Vault in Azure.
AUTHOR/S: Michał Machniak
VERSION: 1.0.0
*/

/*******************
*   Target Scope   *
*******************/

targetScope = 'resourceGroup'

/*******************
*      Types       *
*******************/

@export()
@description('The type for restore settings.')
type restoreSettingsType = {
  @description('Required. The restore settings of the vault.')
  crossSubscriptionRestoreSettings: {
    @description('Required. The restore settings of the vault.')
    crossSubscriptionRestoreState: string
  }
}

@description('Shape of the managed identity configuration.')
type managedIdentitiesType = {
  @description('Optional. Whether to enable the system-assigned identity. Defaults to false.')
  system_assigned: bool?

  @description('Optional. Resource IDs of user-assigned identities to attach. Defaults to none.')
  user_assigned_resource_ids: string[]?
}

@description('The type for soft delete settings.')
type softDeleteSettingType = {
  @description('Required. The enhanced security state.')
  enhancedSecurityState: ('AlwaysON' | 'Disabled' | 'Enabled' | 'Invalid')

  @description('Required. The soft delete retention period in days.')
  softDeleteRetentionPeriodInDays: int

  @description('Required. The soft delete state.')
  softDeleteState: ('AlwaysON' | 'Disabled' | 'Enabled' | 'Invalid')
}

@export()
@description('The type for source scan configuration.')
type sourceScanConfigurationType = {
  @description('Optional. Identity details to be used for the source scan operation.')
  sourceScanIdentity: {
    @description('Required. Identity type that should be used for an operation.')
    operationIdentityType: ('SystemAssigned' | 'UserAssigned')

    @description('Optional. User assigned identity to be used for an operation if operationIdentityType is UserAssigned.')
    userAssignedIdentity: string?
  }?

  @description('Required. The source scan state.')
  state: ('Disabled' | 'Enabled' | 'Invalid')
}

@export()
@discriminator('standardTierStorageRedundancy')
@description('The type for the recovery services vault\'s redundancy settings.')
type redundancySettingsType = redundancySettingsGeoType | redundancySettingsLocalType | redundancySettingsZoneType

type redundancySettingsGeoType = {
  @description('Required. The storage redundancy setting of a vault.')
  standardTierStorageRedundancy: 'GeoRedundant'

  @description('Optional. Flag to show if Cross Region Restore is enabled on the Vault or not.')
  crossRegionRestore: 'Enabled' | 'Disabled'?
}

type redundancySettingsLocalType = {
  @description('Required. The storage redundancy setting of a vault.')
  standardTierStorageRedundancy: 'LocallyRedundant'
}

type redundancySettingsZoneType = {
  @description('Required. The storage redundancy setting of a vault.')
  standardTierStorageRedundancy: 'ZoneRedundant'
}

/*******************
*    Parameters    *
*******************/

@description('Required. The name of the Recovery Services Vault.')
param par_rv_name string

@description('Optional. Location of the Recovery Services Vault. Defaults to the resource group location.')
param par_location string = resourceGroup().location


@description('Optional. Managed identity configuration for the Recovery Services Vault. Defaults to no identity: system-assigned disabled and no user-assigned identities attached.')
param par_managed_identities managedIdentitiesType = {
  system_assigned: false
  user_assigned_resource_ids: []
}

@description('Optional. Tags to be applied to the Recovery Services Vault. Defaults to an empty object.')
param par_tags object = {}

@description('Optional. Specifies whether the Recovery Services Vault should allow public network access. Defaults to Enabled.')
@allowed([
  'Disabled'
  'Enabled'
])
param par_public_network_access string = 'Enabled'

@description('Optional. Alerts for all failover issues. Defaults to Enabled.')
param par_alerts_for_all_failover_issues string = 'Enabled'
@description('Optional. Alerts for all job failures. Defaults to Enabled.')
param par_alerts_for_all_job_failures string = 'Enabled'
@description('Optional. Alerts for all replication issues. Defaults to Enabled.')
param par_alerts_for_all_replication_issues string = 'Enabled'
@description('Optional. Alerts for critical operations. Defaults to Enabled.')
param par_alerts_for_critical_operations string = 'Enabled'
@description('Optional. Email notifications for site recovery. Defaults to Enabled.')
param par_email_notifications_for_site_recovery string = 'Enabled'


@description('Optional. The soft delete related settings.')
param par_soft_delete_settings softDeleteSettingType?

@description('Optional. The immmutability setting state of the recovery services vault resource.')
@allowed([
  'Disabled'
  'Locked'
  'Unlocked'
])
param par_immutability_setting_state string?

@description('Optional. The source scan configuration of the vault security settings.')
param par_source_scan_configuration sourceScanConfigurationType?

@description('Optional. The redundancy settings of the vault.')
param par_redundancy_settings redundancySettingsType?

/*******************
*    Variables     *
*******************/

var var_user_assigned_resource_ids = par_managed_identities.?user_assigned_resource_ids ?? []

var var_system_assigned = par_managed_identities.?system_assigned ?? false

var var_identity_type = var_system_assigned
  ? (empty(var_user_assigned_resource_ids) ? 'SystemAssigned' : 'SystemAssigned,UserAssigned')
  : (empty(var_user_assigned_resource_ids) ? 'None' : 'UserAssigned')

var var_user_assigned_identities = reduce(
  map(var_user_assigned_resource_ids, id => { '${id}': {} }),
  {},
  (current, next) => union(current, next)
)

var var_identity = var_identity_type == 'None'
  ? null
  : {
      type: var_identity_type
      userAssignedIdentities: empty(var_user_assigned_identities) ? null : var_user_assigned_identities
    }

/*******************
*    Resources     *
*******************/

resource res_recovery_vault_services 'Microsoft.RecoveryServices/vaults@2026-07-01' = {
  name: par_rv_name
  location: par_location
  tags: par_tags
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  identity: var_identity
  properties: {
    publicNetworkAccess: par_public_network_access
    monitoringSettings: {
      azureMonitorAlertSettings: {
        alertsForAllFailoverIssues: par_alerts_for_all_failover_issues
        alertsForAllJobFailures: par_alerts_for_all_job_failures
        alertsForAllReplicationIssues: par_alerts_for_all_replication_issues
      }
      classicAlertSettings: {
        alertsForCriticalOperations: par_alerts_for_critical_operations
        emailNotificationsForSiteRecovery: par_email_notifications_for_site_recovery
      }
    }
    securitySettings: {
      immutabilitySettings: !empty(par_immutability_setting_state)
        ? {
            state: par_immutability_setting_state
          }
        : null
      softDeleteSettings: par_soft_delete_settings
      sourceScanConfiguration: par_source_scan_configuration
    }
    redundancySettings: (!empty(par_redundancy_settings))
      ? {
          standardTierStorageRedundancy: par_redundancy_settings!.standardTierStorageRedundancy
          crossRegionRestore: par_redundancy_settings.?crossRegionRestore ?? 'Disabled'
        }
      : null
  }
}




/*******************
*     Outputs      *
*******************/

@description('Name of the Recovery Services Vault created.')
output out_recovery_vault_name string = res_recovery_vault_services.name

@description('Resource ID of the Recovery Services Vault created.')
output out_recovery_vault_id string = res_recovery_vault_services.id

@description('Identity type of the Recovery Services Vault created. Possible values are None, SystemAssigned, UserAssigned, or SystemAssigned,UserAssigned.')
output out_recovery_vault_identity_type string = res_recovery_vault_services.identity.type


@description('Principal ID of the Recovery Services Vault created.')
output out_recovery_vault_principal_id string = reference(res_recovery_vault_services.id, '2023-02-01', 'Full').identity.principalId
