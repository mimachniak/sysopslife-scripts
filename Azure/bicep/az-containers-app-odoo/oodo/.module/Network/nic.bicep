param par_subnet_id string
param par_vm_name string

@allowed([
  'Dynamic'
  'Static'
])
param par_private_ip_allocation_method string = 'Dynamic'
param par_private_ip_address string = ''
param par_network_security_group_id string = ''
param par_public_ip_id string = ''


resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${par_vm_name}-nic-${substring((uniqueString(resourceGroup().id)),0,2)}'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: par_subnet_id
          }
          privateIPAddress: par_private_ip_address == '' ? null: par_private_ip_address
          privateIPAllocationMethod: par_private_ip_allocation_method
          publicIPAddress: par_public_ip_id == '' ? null : {
            id: par_public_ip_id
          }   
        }
      }
    ]
    networkSecurityGroup: par_network_security_group_id == '' ? null : {
      id: par_network_security_group_id
    }    
  }
}

output out_nic_name string = nic.name
output out_nic_id string = nic.id
