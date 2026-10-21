
targetScope = 'resourceGroup'

metadata version = '0.4.0'
metadata author = 'NestLease-DR maintainers'
metadata description = 'Deploys an Azure Bastion host and its public IP address.'
metadata lastUpdated = '2026-10-21'

//MARK: PARAMETERS

@description('Name of the Bastion host and its associated public IP address.')
param par_name string

@description('Tags applied to the Bastion host and public IP address.')
param par_tags object

@description('Azure region where the Bastion host and public IP address are deployed.')
param par_location string = resourceGroup().location

@description('The name of SKU this Bastion Host.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param par_bastion_sku string = 'Basic'

@description('Enable/Disable Copy/Paste feature of the Bastion Host resource.')
param par_disable_copy_paste bool = false

// @description('FQDN for the endpoint on which bastion host is accessible.')
// param par_dns_name string = ''

@description('Enable/Disable File Copy feature of the Bastion Host resource.')
param par_enable_file_copy bool = false

@description('Enable/Disable IP Connect feature of the Bastion Host resource.')
param par_enable_ip_connect bool = false

@description('Enable/Disable Kerberos feature of the Bastion Host resource.')
param par_enable_kerberos bool = false

@description('Enable/Disable Shareable Link of the Bastion Host resource')
param par_enable_shareable_link bool = false

@description('Enable/Disable Session Recording feature of the Bastion Host resource.')
param par_enable_session_recording bool = false

@description('Blob container URI used to store Bastion session recordings when session recording is enabled.')
param par_session_recording_blob_container_uri string = ''

@description('Identity type used by Bastion to access the session recording blob container.')
@allowed([
  'SystemAssigned'
  'UserAssigned'
])
param par_session_recording_identity_type string = 'SystemAssigned'

@description('Resource ID of the user-assigned identity used for session recording; required when the identity type is UserAssigned.')
param par_session_recording_user_assigned_identity_id string = ''

@description('Enable/Disable Tunneling feature of the Bastion Host resource.')
param par_enable_tunneling bool = false
 
@description('Enable/Disable Private Only Bastion feature of the Bastion Host resource.')
param par_enable_private_only_bastion bool = false


@description('The scale units for the Bastion Host resource.')
@minValue(2)
@maxValue(50)
param par_bastion_scale_units int = 2

@description('Private IP allocation method.')
@allowed([
  'Dynamic'
  'Static'
])
param par_bastion_private_ip_allocation_method string = 'Dynamic'

@description('Reference of the subnet resource.')
param par_bastion_subnet_id string

//MARK: RESOURCES

resource res_bastion_pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: '${par_name}-PIP'
  location: par_location
  tags: par_tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource res_bastion 'Microsoft.Network/bastionHosts@2026-01-01' = {
  name: par_name
  location: par_location
  tags: par_tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: par_bastion_sku
  }
  properties: {
    disableCopyPaste: par_disable_copy_paste
    enableFileCopy: par_enable_file_copy
    enableIpConnect: par_enable_ip_connect
    enableKerberos: par_enable_kerberos
    enableShareableLink: par_enable_shareable_link
    enableTunneling: par_enable_tunneling
    enableSessionRecording: par_enable_session_recording
    sessionRecordingConfiguration: par_enable_session_recording ? {
      blobContainerUri: par_session_recording_blob_container_uri
      identity: par_session_recording_identity_type == 'UserAssigned' ? {
        type: par_session_recording_identity_type
        userAssignedIdentityId: par_session_recording_user_assigned_identity_id
      } : {
        type: par_session_recording_identity_type
      }
    } : null
    enablePrivateOnlyBastion: par_enable_private_only_bastion
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: par_bastion_private_ip_allocation_method
          publicIPAddress: {
            id: res_bastion_pip.id
          }
          subnet: {
            id: par_bastion_subnet_id
          }
        }
      }
    ]
    scaleUnits: par_bastion_scale_units
  }
}

//MARK: OUTPUTS

@description('Resource ID of the Bastion host.')
output out_bastion_id string = res_bastion.id

@description('Name of the Bastion host.')
output out_bastion_name string = res_bastion.name

@description('DNS name of the Bastion host.')
output out_bastion_dns_name string = res_bastion.properties.dnsName

@description('Resource ID of the Bastion public IP address.')
output out_bastion_public_ip_id string = res_bastion_pip.id

@description('IP address allocated to the Bastion public IP resource.')
output out_bastion_public_ip_address string = res_bastion_pip.properties.ipAddress
