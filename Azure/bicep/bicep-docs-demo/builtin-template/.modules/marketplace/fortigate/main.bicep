/*******************
*   Target Scope   *
*******************/

targetScope = 'resourceGroup'

/*******************
*      Types       *
*******************/

@description('Required. The name of the Recovery Services Vault.')
param par_name string

@description('Optional. Location of the Recovery Services Vault. Defaults to the resource group location.')
param par_location_name string = resourceGroup().location

@description('Optional. Tags to be applied to the Recovery Services Vault. Defaults to an empty object.')
param par_tags object = {}

@description('Optional. The admin username for the virtual machine. Defaults to "jiouronog".')
param par_forti_gate_admin_username string = 'jiouronog'

@description('Required. The ID of the external subnet for the FortiGate virtual machine.')
param par_forti_gate_external_subnet_id string

@description('Required. External IP address for the FortiGate virtual machine.')
param par_forti_gate_external_ip string



@description('Required. The ID of the internal subnet for the FortiGate virtual machine.')
param par_forti_gate_internal_subnet_id string

@description('Required. Internal IP address for the FortiGate virtual machine.')
param par_forti_gate_internal_ip string

@description('Optional. The size of the FortiGate virtual machine. Defaults to "Standard_D4ls_v6".')
param par_forti_gate_vm_size string = 'Standard_D4ls_v6'

/*
@description('Identifies whether to to use PAYG (on demand licensing) or BYOL license model (where license is purchased separately).')
@allowed([
  'fortinet_fg-vm_byol'
  'fortinet_fg-vm_payg'
])
param par_forti_gate_license_type string

@description('Indicates the instance Architecture of the VM deployment. Intel/AMD, Intel/AMD gen2 VM or ARM')
@allowed([
  'x64'
  '_g2'
  '_arm64'
])
param par_forti_gate_instance_architecture string = '_g2'

@description('Select the image version supporting Generation 1 VMs')
@allowed([
    '7.4.11'
    '7.2.13'
    '7.0.19'
])
param parr_forti_gate_image_version_x64 string = '7.4.11'



@description('Select the image version supporting Generation 2 VMs')
@allowed([
    '8.0.0'
    '7.6.7'
    '7.4.12'
])
param par_forti_gate_image_version_x64_g2 string = '8.0.0'


@description('Select the image version supporting ARM64 VMs')
@allowed([
    '8.0.0'
    '7.6.7'
    '7.4.12'
    '7.4.11'
    '7.2.13'
])
param par_forti_gate_image_version_arm64 string = '8.0.0'

@description('Specifies the security type for the virtual machine. Options are Standard or TrustedLaunch.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param par_vm_security_type string = 'Standard'

param par_instance_type_x64_g2 string = 'Standard_D4ls_v6'
param par_vm_security_tpm bool = false

param par_availability_options string = 'None'
param par_accelerated_networking bool = false

param par_serial_console bool = true


param par_forti_manager string = 'no'
param par_forti_manager_ip string = ''
param par_forti_manager_serial string = ''
*/

/*******************
*    Resources     *
*******************/

resource res_public_ip_addresses 'Microsoft.Network/publicIPAddresses@2025-07-01' = {
  name: '${par_name}-PIP'
  location: par_location_name
  tags: par_tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: toLower('${par_name}')
      fqdn: '${toLower(par_name)}.eastus.cloudapp.azure.com'
    }
    ipTags: []
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
  }
}


resource res_network_interfaces_internal 'Microsoft.Network/networkInterfaces@2025-07-01' = {
  name: '${par_name}-nic2'
  location: par_location_name
  tags: par_tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: par_forti_gate_internal_ip
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: par_forti_gate_internal_subnet_id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: true
    disableTcpStateTracking: false
    /*networkSecurityGroup: {
      id: networkSecurityGroups_FG_VM_nsg_name_resource.id
    }
    */
    nicType: 'Standard'
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
  }
}


resource res_network_interfaces_external 'Microsoft.Network/networkInterfaces@2025-07-01' = {
  name: '${par_name}-nic1'
  location: par_location_name
  tags: par_tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: par_forti_gate_external_ip
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: res_public_ip_addresses.id
          }
          subnet: {
            id: par_forti_gate_external_subnet_id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: true
    disableTcpStateTracking: false
    /*
    networkSecurityGroup: {
      id: networkSecurityGroups_FG_VM_nsg_name_resource.id
    }
    */
    nicType: 'Standard'
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
  }
}




resource virtualMachines_fgbdbd_FG_fgt_name_resource 'Microsoft.Compute/virtualMachines@2026-03-01' = {
  name: par_name
  location: par_location_name
  tags: par_tags
  identity: {
    type: 'SystemAssigned'
  }
  plan: {
    name: 'fortinet_fg-vm_payg_80_g2'
    product: 'fortinet_fortigate-vm'
    publisher: 'fortinet'
  }
  properties: {
    hardwareProfile: {
      vmSize: par_forti_gate_vm_size
    }
    storageProfile: {
      imageReference: {
        publisher: 'fortinet'
        offer: 'fortinet_fortigate-vm'
        sku: 'fortinet_fg-vm_payg_80_g2'
        version: '8.0.0'
      }
      osDisk: {
        osType: 'Linux'
        name: '${par_name}_OsDisk_1_87509d6ac4d54675af13bfb6422cfca1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
          id: resourceId(
            'Microsoft.Compute/disks',
            '${par_name}_OsDisk_1_87509d6ac4d54675af13bfb6422cfca1'
          )
        }
        deleteOption: 'Detach'
        diskSizeGB: 2
      }
      dataDisks: [
        {
          lun: 0
          name: '${par_name}_disk2_ae6e0472639c42ba9a6ea30cc4b0c96c'
          createOption: 'Empty'
          caching: 'None'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
            id: resourceId(
              'Microsoft.Compute/disks',
              '${par_name}_disk2_ae6e0472639c42ba9a6ea30cc4b0c96c'
            )
          }
          deleteOption: 'Detach'
          diskSizeGB: 30
          toBeDetached: false
        }
      ]
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: par_name
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: true
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
      adminUsername: par_forti_gate_admin_username
    }
    securityProfile: {
      securityType: 'Standard'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: res_network_interfaces_external.id
          properties: {
            primary: true
          }
        }
        {
          id: res_network_interfaces_internal.id
          properties: {
            primary: false
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}





/*******************
*     Outputs      *
*******************/

@description('The external IP address of the FortiGate virtual machine.')
output out_external_ip string = res_public_ip_addresses.properties.ipAddress

@description('The external DNS name of the FortiGate virtual machine.')
output out_external_dns string = res_public_ip_addresses.properties.dnsSettings.domainNameLabel

