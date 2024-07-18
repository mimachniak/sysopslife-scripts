targetScope = 'subscription'
param location string = deployment().location
param pra_rg_name string
param par_tags object
resource res_rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  location: location
  name: pra_rg_name
  tags: par_tags
}
output out_rg_id string = res_rg.id
output out_rg_name string = res_rg.name
