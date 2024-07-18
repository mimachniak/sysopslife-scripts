param par_network_security_group_name string
param par_tags object
param par_security_rules array = []

resource res_Network_Security_Group 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: par_network_security_group_name
  location: resourceGroup().location
  tags: par_tags
  properties:{
    securityRules:par_security_rules
    
  }
}

output out_nsg_id string = res_Network_Security_Group.id
output out_nsg_name string = res_Network_Security_Group.name
