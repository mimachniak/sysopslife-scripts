# Recovery Services Vault

Deploys a Recovery Services Vault in Azure.

## Summary

Module to deploy a Recovery Services Vault with backup capabilities.

## Module Information

| Property | Value |
|----------|-------|
| Owner    | platform-team |
| Support  | azure-admin@euvic.pl |
| Version  | 1.0.2 |

## Resource Types

| Resource Type |
|---------------|
| `Microsoft.RecoveryServices/vaults` |
| `Microsoft.RecoveryServices/vaults/replicationAlertSettings` |

## Usage

```bicep
module recovery_vault 'br:geitbicepmodweucr01.azurecr.io/bicep/modules/backup/recovery_vault:1.0.2' = {
  name: 'recovery_vault'
  params: {
    // Required parameters
    par_rv_name: <string>
  }
}
```

## Parameters

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `par_alerts_for_all_failover_issues` | `string` | Optional. Whether to display alerts in Azure Monitor for all failover issues. Defaults to Enabled. | `Enabled` |
| `par_alerts_for_all_job_failures` | `string` | Optional. Whether to display alerts in Azure Monitor for all job failures. Defaults to Enabled. | `Enabled` |
| `par_alerts_for_all_replication_issues` | `string` | Optional. Whether to display alerts in Azure Monitor for all replication issues. Defaults to Enabled. | `Enabled` |
| `par_alerts_for_critical_operations` | `string` | Optional. Whether to display alerts in Azure Monitor for critical operations. Defaults to Disabled. | `Disabled` |
| `par_email_notifications_for_site_recovery` | `string` | Optional. Whether to send classic email notifications for Site Recovery events. Defaults to Enabled. | `Enabled` |
| `par_immutability_state` | `string` | Optional. Immutability state for the vault. Unlocked by default, which protects backups from being deleted or shortened while remaining reversible. Locked makes immutability permanent: it cannot be relaxed or removed afterwards, by anyone, for the life of the vault. Set Locked only when that is deliberate. | `Unlocked` |
| `par_location` | `string` | Optional. Location of the Recovery Services Vault. Defaults to the resource group location. | `[resourceGroup().location]` |
| `par_managed_identities` | `managedIdentitiesType` | Optional. Managed identity configuration for the Recovery Services Vault. Defaults to no identity: system-assigned disabled and no user-assigned identities attached. | `@{system_assigned=False; user_assigned_resource_ids=System.Object[]}` |
| `par_public_network_access` | `string` | Optional. Specifies whether the Recovery Services Vault should allow public network access. Defaults to Enabled. | `Enabled` |
| `par_replication_alert_settings` | `replicationAlertSettingsType` | Optional. Replication alert configuration. Defaults to alerting subscription owners, which needs no consumer input and stays inert on a vault that performs no replication. Set sendToOwners to DoNotSend, with no custom addresses, to switch replication alerting off. | `@{sendToOwners=Send}` |
| `par_rv_name` | `string` | Required. The name of the Recovery Services Vault. | _required_ |
| `par_tags` | `object` | Optional. Tags to be applied to the Recovery Services Vault. Defaults to an empty object. | `` |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `out_recovery_vault_id` | `string` | Resource ID of the Recovery Services Vault created. |
| `out_recovery_vault_name` | `string` | Name of the Recovery Services Vault created. |
