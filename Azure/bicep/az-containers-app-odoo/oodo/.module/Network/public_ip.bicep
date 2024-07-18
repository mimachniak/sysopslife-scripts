targetScope = 'resourceGroup'

param par_public_ip_name string
param par_public_ip_sku object = {
  name: 'Basic'
  tier: 'Regional'
}
//param par_public_ip_properties object
param par_tags object

resource res_public_ip 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: par_public_ip_name
  location: resourceGroup().location
  tags: par_tags
  sku: par_public_ip_sku
  //properties: par_public_ip_properties
}
output out_public_ip_Id string = res_public_ip.id
