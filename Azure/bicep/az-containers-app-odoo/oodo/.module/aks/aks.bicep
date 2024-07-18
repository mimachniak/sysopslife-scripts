param par_aks_name string
param par_aks_administrators_aad_groupd_ids array
param par_log_workspace_id string
param par_private_dns_zone_id string = ''
param par_aks_mui_identity_id object
param par_aks_resource_group_name string
param par_aks_private_cluster bool
param par_aks_network_octet string
param par_aks_version string

@description('The agent pool properties.')
param par_aks_agent_pool_profile array

@description('This can only be set at cluster creation time and cannot be changed later. For more information see egress outbound type.')
@allowed([
  'loadBalancer'
  'managedNATGateway'
  'userAssignedNATGateway'
  'userDefinedRouting'
])
param par_aks_outbound_type string = 'loadBalancer'

@description('	The default is standard. See Azure Load Balancer SKUs for more information about the differences between load balancer SKUs')
@allowed([
  'basic'
  'standard'
])
param par_load_balancer_sku string = 'standard'

@description('Network policy used for building the Kubernetes network.')
@allowed([
  'azure'
  'calico'
])
param par_aks_network_mode string = 'azure'

param par_tags object



resource res_aks_cluster 'Microsoft.ContainerService/managedClusters@2022-01-01' = {
  name: par_aks_name
  location: resourceGroup().location
  tags: par_tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: par_aks_mui_identity_id
  }
  properties: {
    kubernetesVersion: par_aks_version
    nodeResourceGroup: par_aks_resource_group_name
    dnsPrefix: '${par_aks_name}-dns'
    agentPoolProfiles: par_aks_agent_pool_profile
    networkProfile: {     
      networkPlugin: 'azure'
      outboundType: par_aks_outbound_type
      dockerBridgeCidr: '192.${par_aks_network_octet}.0.1/12'
      dnsServiceIP: '10.${par_aks_network_octet}.0.10'
      serviceCidr: '10.${par_aks_network_octet}.0.0/24'
      networkPolicy: par_aks_network_mode
      loadBalancerSku: par_load_balancer_sku
      loadBalancerProfile: {
        managedOutboundIPs: {
          count: 1
        }
      }
    }
    apiServerAccessProfile: {
      enablePrivateCluster: par_aks_private_cluster
      privateDNSZone: par_aks_private_cluster  == false ? par_private_dns_zone_id : ''
    }
    enableRBAC: true
    aadProfile: {
      adminGroupObjectIDs: par_aks_administrators_aad_groupd_ids
      enableAzureRBAC: true
      managed: true
      tenantID: subscription().tenantId
    }
    autoScalerProfile: {
      'balance-similar-node-groups': 'true' // Detects similar node pools and balances the number of nodes between them
      'expander': 'most-pods'
     }
    addonProfiles:{
      omsagent: {
        config: {
          logAnalyticsWorkspaceResourceID: par_log_workspace_id
        }
        enabled: true
      }
      azurepolicy: {
        enabled: true
      }
      httpApplicationRouting:{
        enabled: false
      }
    }
  }
}

///

output aks_agent_pool_id string = res_aks_cluster.properties.identityProfile.kubeletidentity.objectId

