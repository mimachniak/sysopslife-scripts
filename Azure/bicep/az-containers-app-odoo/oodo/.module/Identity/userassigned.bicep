param par_basename string
param par_tags object

resource res_user_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: par_basename
  location: resourceGroup().location
  tags: par_tags
}

output out_identity_id string = res_user_identity.id
output out_client_Id string = res_user_identity.properties.clientId
output out_principal_id string = res_user_identity.properties.principalId
