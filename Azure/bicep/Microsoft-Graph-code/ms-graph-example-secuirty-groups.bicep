
extension 'br:mcr.microsoft.com/bicep/extensions/microsoftgraph/beta:1.0.0' // Load beta extension
extension 'br:mcr.microsoft.com/bicep/extensions/microsoftgraph/v1.0:1.0.0' // Load v1.0 extension

resource res_account_v1 'Microsoft.Graph/users@v1.0' existing = {
  userPrincipalName: 'Tomasz.Oscypek@sys4ops.pl' // Existing user only supported in this edition
}

output accountId_v1 string = res_account_v1.id


resource res_account_beta 'Microsoft.Graph/users@beta' existing = {
  userPrincipalName: 'Tomasz.Oscypek@sys4ops.pl' // Existing user only supported in this edition
}

output accountId_beta string = res_account_beta.id


resource res_secuirty_group_beta 'Microsoft.Graph/groups@beta' = {
  displayName: 'Bicep Beta Security Group'
  description: 'Security group created by Bicep Beta extension'
  securityEnabled: true
  mailEnabled: false // Need to be false is not supported by v1.0 and beta
  mailNickname: 'bicep-beta-security-group'
  owners: {
    relationships: [res_account_beta.id]
  }
  uniqueName: 'BicepBetaSecurityGroup' // No whitspaces allowed

}

resource res_secuirty_group_v1 'Microsoft.Graph/groups@beta' = {
  displayName: 'Bicep Security Group'
  description: 'Security group created by Bicep extension'
  securityEnabled: true
  mailEnabled: false // Need to be false is not supported by v1.0 and beta
  mailNickname: 'bicep-security-group'
  uniqueName: 'BicepSecurityGroup' // No whitspaces allowed
  members: {
    relationships: [res_account_v1.id]
  }


}
