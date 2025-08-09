targetScope = 'tenant'

extension 'br:mcr.microsoft.com/bicep/extensions/microsoftgraph/beta:1.0.0' // Load beta extension
extension 'br:mcr.microsoft.com/bicep/extensions/microsoftgraph/v1.0:1.0.0' // Load v1.0 extension

///////////////////////// PARAMETERS /////////////////////////

param par_list_secuirty_groups_name array = [
  {
    name: 'GAL-AAD-MG-Organization-Org-Reader'
    description: 'Security group with permissions to read the management group hierarchy'
    role: 'Reader'
    securityEnabled: true
    mailEnabled: false // Need to be false is not supported by v1.0 and beta
    uniqueName: 'GALAADMGXYZOrgOrgReader' // No whitspaces allowed
    MangmentGroupId: 'Organization' // Management Group ID to assign the group to
  }
  {
    name: 'GAL-AAD-MG-Organization-Contributor'
    description: 'Security group with permissions to contribute to the management group hierarchy'
    role: 'Contributor'
    securityEnabled: true
    mailEnabled: false // Need to be false is not supported by v1.0 and beta
    uniqueName: 'GALAADMGXYZOrgOrgContributor' // No whitspaces allowed
    MangmentGroupId: 'Organization' // Management Group ID to assign the group to
  }
  {
    name:'GAL-AAD-MG-Organization-Owner'
    description: 'Security group with permissions to manage the management group hierarchy'
    role: 'Owner'
    securityEnabled: true
    mailEnabled: false // Need to be false is not supported by v1.0 and beta
    uniqueName: 'GALAADMGXYZOrgOrgOwner' // No whitspaces allowed
    MangmentGroupId: 'Organization' // Management Group ID to assign the group to
  }
  // Dev Groups
  {
    name: 'GAL-AAD-MG-DEV-Reader'
    description: 'Security group with permissions to read the management group hierarchy'
    role: 'Reader'
    securityEnabled: true
    mailEnabled: false // Need to be false is not supported by v1.0 and beta
    uniqueName: 'GALAADMGDEVReader' // No whitspaces allowed
    MangmentGroupId: 'DEV' // Management Group ID to assign the group to
  }
  {
    name: 'GAL-AAD-MG-DEV-Contributor'
    description: 'Security group with permissions to contribute to the management group hierarchy'
    role: 'Contributor'
    securityEnabled: true
    mailEnabled: false // Need to be false is not supported by v1.0 and beta
    uniqueName: 'GALAADMGDEVContributor' // No whitspaces allowed
    MangmentGroupId: 'DEV' // Management Group ID to assign the group to

  }
  {
    name:'GAL-AAD-MG-DEV-Owner'
    description: 'Security group with permissions to manage the management group hierarchy'
    role: 'Owner'
    securityEnabled: true
    mailEnabled: false // Need to be false is not supported by v1.0 and beta
    uniqueName: 'GALAADMGDEVOwner' // No whitspaces allowed
    MangmentGroupId: 'DEV' // Management Group ID to assign the group to
  }
  // Prod groups
  {
    name: 'GAL-AAD-MG-PROD-Reader'
    description: 'Security group with permissions to read the management group hierarchy'
    role: 'Reader'
    securityEnabled: true
    mailEnabled: false // Need to be false is not supported by v1.0 and beta
    uniqueName: 'GALAADMGPRODReader' // No whitspaces allowed
    MangmentGroupId: 'PROD' // Management Group ID to assign the group to
  }
  {
    name: 'GAL-AAD-MG-PROD-Contributor'
    description: 'Security group with permissions to contribute to the management group hierarchy'
    role: 'Contributor'
    securityEnabled: true
    mailEnabled: false // Need to be false is not supported by v1.0 and beta
    uniqueName: 'GALAADMGPRODContributor' // No whitspaces allowed
    MangmentGroupId: 'PROD' // Management Group ID to assign the group to

  }
  {
    name:'GAL-AAD-MG-PROD-Owner'
    description: 'Security group with permissions to manage the management group hierarchy'
    role: 'Owner'
    securityEnabled: true
    mailEnabled: false // Need to be false is not supported by v1.0 and beta
    uniqueName: 'GALAADMGPRODOwner' // No whitspaces allowed
    MangmentGroupId: 'PROD' // Management Group ID to assign the group to
  }
    // Prod Default
  {
    name: 'GAL-AAD-MG-Default-Reader'
    description: 'Security group with permissions to read the management group hierarchy'
    role: 'Reader'
    securityEnabled: true
    mailEnabled: false // Need to be false is not supported by v1.0 and beta
    uniqueName: 'GALAADMGDefualtReader' // No whitspaces allowed
    MangmentGroupId: 'Default' // Management Group ID to assign the group to
  }
  {
    name: 'GAL-AAD-MG-Default-Contributor'
    description: 'Security group with permissions to contribute to the management group hierarchy'
    role: 'Contributor'
    securityEnabled: true
    mailEnabled: false // Need to be false is not supported by v1.0 and beta
    uniqueName: 'GALAADMDefualtContributor' // No whitspaces allowed
    MangmentGroupId: 'Default' // Management Group ID to assign the group to
  }
  {
    name:'GAL-AAD-MG-Default-Owner'
    description: 'Security group with permissions to manage the management group hierarchy'
    role: 'Owner'
    securityEnabled: true
    mailEnabled: false // Need to be false is not supported by v1.0 and beta
    uniqueName: 'GALAADMGDefualtOwner' // No whitspaces allowed
    MangmentGroupId: 'Default' // Management Group ID to assign the group to
  }

]


resource res_secuirty_group_alz 'Microsoft.Graph/groups@beta' = [for sec_group in par_list_secuirty_groups_name: {
  displayName: sec_group.name
  description: sec_group.description
  securityEnabled: true
  mailEnabled: false // Need to be false is not supported by v1.0 and beta
  mailNickname: toLower('${sec_group.name}')
  owners: {
    relationships: []
  }
  members: {
    relationships: []
  }
  uniqueName: sec_group.uniqueName  // No whitspaces allowed

}]



// Assign security groups to management groups - need delay against the creation of the security groups

module mod_mg_role_permissions '.modules/RoleAssigment/managmentGroups.bicep' = [for i in range(0, length(par_list_secuirty_groups_name)) : {
  name: guid(par_list_secuirty_groups_name[i].name)
  scope: managementGroup('${par_list_secuirty_groups_name[i].MangmentGroupId}')
  params: {
    principalId: res_secuirty_group_alz[i].id
    roleDefinitionIdOrName: par_list_secuirty_groups_name[i].role
    managementGroupId: par_list_secuirty_groups_name[i].MangmentGroupId
  }
  dependsOn: [
    res_secuirty_group_alz
  ]
}]

output out_groups_id array = [for i in range(0, length(par_list_secuirty_groups_name)): res_secuirty_group_alz[i].id]

//





