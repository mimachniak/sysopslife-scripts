/*
SUMMARY: Windows virtual machine with optional public IP, Azure AD login, and domain join.
DESCRIPTION: Deploys a Windows VM with network, disk, patch, and optional directory integrations.
AUTHOR/S: NestLease-DR maintainers
VERSION: 1.0.0
*/

targetScope = 'resourceGroup'

type imageReferenceType = {
  @description('Image publisher.')
  publisher: string

  @description('Image offer.')
  offer: string

  @description('Image SKU.')
  sku: string

  @description('Image version.')
  version: string
}

type dataDiskType = {
  @description('Disk creation option.')
  createOption: string

  @description('Disk caching mode.')
  caching: 'None' | 'ReadOnly' | 'ReadWrite'

  @description('Whether write accelerator is enabled.')
  writeAcceleratorEnabled: bool

  @description('Disk size in GiB.')
  diskSizeGB: int

  @description('Managed disk storage account type.')
  storageAccountType: string
}

//MARK: PARAMETERS

/*
VM sizes follow the Azure naming convention:
[Family][Sub-family][vCPUs][Features][Accelerator][Version].
*/

@description('Windows VM and computer name. Must be 1-15 characters.')
@minLength(1)
@maxLength(15)
param par_vm_name string

@description('Resource ID of the subnet for the VM network interface.')
param par_vm_subnet_id string

@description('Azure region for the VM and related resources.')
param par_location string = resourceGroup().location

@description('Private IP allocation method for the VM network interface.')
@allowed([
  'Dynamic'
  'Static'
])
param par_private_ip_allocation_method string = 'Dynamic'

@description('Optional static private IP address. Leave empty for dynamic allocation.')
param par_private_ip_address string = ''

@description('Azure VM size.')
param par_vm_size string = 'Standard_B2s'

@description('Tags to apply to the VM and related resources.')
param par_tags object

@description('Marketplace image reference for the VM operating system.')
param par_image_reference imageReferenceType = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2022-datacenter-azure-edition'
  version: 'latest'
}

@description('Network security rules passed to the network security group module.')
param par_security_rules array = []

@description('Storage SKU for the VM operating system disk.')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'StandardSSD_LRS'
  'StandardSSD_ZRS'
  'Standard_LRS'
  'UltraSSD_LRS'
])
param par_os_disk_sku_name string = 'Standard_LRS'

@description('Whether automatic Windows updates are enabled.')
param par_vm_automatic_updates bool = true

@description('Patch mode for the Windows VM.')
@allowed([
  'AutomaticByOS'
  'AutomaticByPlatform'
  'Manual'
])
param par_vm_patch_mode string = 'AutomaticByOS'

@description('Administrator account name for the Windows VM.')
param par_vm_admin_name string = 'adm.user'

@description('Administrator account password for the Windows VM.')
@secure()
param par_vm_admin_password string

@description('Name and type of the Azure AD login VM extension.')
param par_aad_login_extension_name string = 'AADLoginForWindows'

@description('Whether to install the Azure AD login extension.')
param par_aad_login_enable bool = false

@description('Whether to create and attach a public IP address.')
param par_vm_public_ip_creation bool = false

@description('Data disks to attach to the VM.')
param par_vm_data_disks dataDiskType[] = []

@description('Operating system disk size in GiB.')
param par_vm_os_data_disks_size int = 127

@description('Whether to join the VM to an Active Directory domain.')
param par_ad_join_enable bool = false

@description('Active Directory domain name for the VM to join.')
param par_ad_join_domain string = ''

@description('Administrator account name for the Active Directory domain.')
param par_ad_join_user string = ''

@description('Administrator account password for the Active Directory domain.')
@secure()
param par_ad_join_user_password string = ''

@description('Optional organizational unit distinguished name for the VM computer account.')
param par_ad_join_ou_path string = ''

//MARK: VARIABLES

var var_network_security_group_name = '${par_vm_name}-NSG'
var var_public_ip_name = '${par_vm_name}-PIP'
var var_network_interface_name = '${par_vm_name}-nic-${substring(uniqueString(resourceGroup().id), 0, 2)}'
var var_public_ip_id = par_vm_public_ip_creation ? (res_pip.?id ?? '') : ''

//MARK: RESOURCES

resource res_nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: var_network_security_group_name
  location: par_location
  tags: par_tags
  properties: {
    securityRules: par_security_rules
  }
}

resource res_pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = if (par_vm_public_ip_creation) {
  name: var_public_ip_name
  location: par_location
  tags: par_tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower(var_public_ip_name)
    }
  }
}

resource res_nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: var_network_interface_name
  location: par_location
  tags: par_tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: par_vm_subnet_id
          }
          privateIPAddress: empty(par_private_ip_address) ? null : par_private_ip_address
          privateIPAllocationMethod: par_private_ip_allocation_method
          publicIPAddress: empty(var_public_ip_id) ? null : {
            id: var_public_ip_id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: res_nsg.id
    }
  }
}

resource res_vm 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: par_vm_name
  location: par_location
  tags: par_tags
  properties: {
    hardwareProfile: {
      vmSize: par_vm_size
    }
    storageProfile: {
      osDisk: {
        name: '${par_vm_name}-OSDisk'
        createOption: 'FromImage'
        osType: 'Windows'
        caching: 'ReadWrite'
        writeAcceleratorEnabled: false
        managedDisk: {
          storageAccountType: par_os_disk_sku_name
        }
        diskSizeGB: par_vm_os_data_disks_size
      }
      imageReference: par_image_reference
      dataDisks: [for (disk, disk_index) in par_vm_data_disks: {
        lun: disk_index
        createOption: disk.createOption
        caching: disk.caching
        writeAcceleratorEnabled: disk.writeAcceleratorEnabled
        diskSizeGB: disk.diskSizeGB
        managedDisk: {
          storageAccountType: disk.storageAccountType
        }
      }]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: res_nic.id
        }
      ]
    }
    osProfile: {
      computerName: par_vm_name
      adminUsername: par_vm_admin_name
      adminPassword: par_vm_admin_password
      windowsConfiguration: {
        enableAutomaticUpdates: par_vm_automatic_updates
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: false
          patchMode: par_vm_patch_mode
        }
      }
    }
  }
}

resource res_vm_extensions 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = if (par_aad_login_enable) {
  parent: res_vm
  name: par_aad_login_extension_name
  location: par_location
  tags: par_tags
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: par_aad_login_extension_name
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
}

resource res_vm_extensions_ad_join 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (par_ad_join_enable) {
  parent: res_vm
  name: 'joindomain'
  location: par_location
  tags: par_tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    settings: {
      Name: par_ad_join_domain
      User: '${par_ad_join_domain}\\${par_ad_join_user}'
      Restart: true
      Options: 3
      OUPath: par_ad_join_ou_path
    }
    protectedSettings: {
      Password: par_ad_join_user_password
    }
  }
}

//MARK: OUTPUTS

@description('Resource ID of the Windows VM.')
output vm_reource_id string = res_vm.id
