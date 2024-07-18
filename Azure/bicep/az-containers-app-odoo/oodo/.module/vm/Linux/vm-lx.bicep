param par_vm_name string
param par_vm_subnet_id string

@allowed([
  'Dynamic'
  'Static'
])
param par_private_ip_allocation_method string = 'Dynamic'
param par_private_ip_address string = ''

param par_vm_size string = 'Standard_B2s'
param par_tags object
param par_image_reference object = {
  publisher: 'canonical'
  offer: '0001-com-ubuntu-server-focal'
  sku: '20_04-lts-gen2'
  version: 'latest'
}
param par_security_rules array = []

@allowed([
'Premium_LRS'
'Premium_ZRS'
'StandardSSD_LRS'
'StandardSSD_ZRS'
'Standard_LRS'
'UltraSSD_LRS'
])
param par_os_disk_sku_name string = 'Premium_LRS'

@allowed([
  'ImageDefault'
  'AutomaticByPlatform'
])
param par_vm_patch_mode string = 'AutomaticByPlatform'
param par_vm_admin_name string = 'admuser'

@secure()
param par_vm_admin_password string

param par_aad_login_extension_name string = 'AADSSHLoginForLinux'

@description('Optional. Integration witch Azure AD RBAC login for VMs')
param par_aad_login_enable bool = false

@description('Optional. Public IP integration')
param par_vm_public_ip_creation bool = true

//// Resources ///

module mod_nsg '../../Network/nsg.bicep' = {
  name: '${par_vm_name}-NSG'
  params: {
    par_network_security_group_name: '${par_vm_name}-NSG'
    par_tags: par_tags
    par_security_rules: par_security_rules
    
  }
}

module mod_pip '../../Network/public_ip.bicep'= if (par_vm_public_ip_creation  == true)  {
  name: '${par_vm_name}-PIP'
  params: {
    par_public_ip_name: '${par_vm_name}-PIP'
    par_tags: par_tags
  }
}

var var_public_ip_id = par_vm_public_ip_creation  == true ? mod_pip.outputs.out_public_ip_Id : ''

module mod_vm_nic '../../Network/nic.bicep' = {
  name: '${par_vm_name}-NIC'
  params: {
    par_subnet_id: par_vm_subnet_id
    par_vm_name: par_vm_name
    par_network_security_group_id: mod_nsg.outputs.out_nsg_id
    par_public_ip_id: var_public_ip_id
    par_private_ip_address: par_private_ip_address
    par_private_ip_allocation_method: par_private_ip_allocation_method
  }
  dependsOn: [
    mod_nsg
    mod_pip
  ]
}

resource res_vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: par_vm_name
  location: resourceGroup().location
  tags: par_tags
  properties: {
    hardwareProfile: {
      vmSize: par_vm_size
    }
    storageProfile:{
      osDisk:{
        name: '${par_vm_name}-OSDisk'
        createOption: 'FromImage'
        osType:'Linux'
        caching:'ReadWrite'
        writeAcceleratorEnabled:false
        managedDisk:{
          storageAccountType: par_os_disk_sku_name
        }
      }
      imageReference: par_image_reference
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: mod_vm_nic.outputs.out_nic_id
        }
      ]
    }
    osProfile: {
      computerName: par_vm_name
      adminUsername: par_vm_admin_name
      adminPassword: par_vm_admin_password
      linuxConfiguration: {
        patchSettings: {
          patchMode: par_vm_patch_mode
        }
        
      }
    }
  }
  dependsOn: [
    mod_vm_nic
  ]
}


resource res_vm_extensions 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = if (par_aad_login_enable == true) {
  name: '${par_vm_name}/${par_aad_login_extension_name}'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: par_aad_login_extension_name
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    res_vm
  ]
}

