# Changelog

## 1.0.2

### Changes

- Completes `classicAlertSettings` with `emailNotificationsForSiteRecovery` add if for null and when alert is disabled.

## 1.0.1

### Changes

- Completes `classicAlertSettings` with `emailNotificationsForSiteRecovery` so Azure accepts the vault monitoring settings payload.

## 1.0.0

### Changes

- Initial release.
- Deploys a `Microsoft.RecoveryServices/vaults` resource on the `RS0` Standard SKU with configurable Azure Monitor and classic alert settings, immutability state, replication alert settings, optional system-assigned and user-assigned identities and tags, and returns `out_recovery_vault_name` and `out_recovery_vault_id`.

### Breaking Changes

- None
