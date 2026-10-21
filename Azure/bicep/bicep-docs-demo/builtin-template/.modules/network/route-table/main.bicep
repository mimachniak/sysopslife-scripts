/*******************
*   Target Scope   *
*******************/

targetScope = 'resourceGroup'

/*******************
*      Types       *
*******************/

type routeType = {
  name: string
  addressPrefix: string
  nextHopType: 'VirtualAppliance' | 'VirtualNetworkGateway' | 'VnetLocal' | 'Internet' | 'None'
  nextHopIpAddress: string
}

@description('Required. The name of the Recovery Services Vault.')
param par_name string

@description('Optional. Location of the Recovery Services Vault. Defaults to the resource group location.')
param par_location_name string = resourceGroup().location

@description('Optional. Tags to be applied to the Recovery Services Vault. Defaults to an empty object.')
param par_tags object = {}

@description('Optional. Routes to add to the route table.')
param par_routes routeType[] = [
]


resource res_route_tables_name_resource 'Microsoft.Network/routeTables@2025-07-01' = {
  name: par_name
  location: par_location_name
  tags: par_tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [for route in par_routes: {
      name: route.name
      properties: {
        addressPrefix: route.addressPrefix
        nextHopType: route.nextHopType
        ...(contains(['VirtualAppliance', 'VirtualNetworkGateway'], route.nextHopType)
          ? {
              nextHopIpAddress: route.nextHopIpAddress
            }
          : {})
      }
    }
    ]
  }
  dependsOn: [
]
} 

@description('The ID of the created route table.')
output out_route_table_id string = res_route_tables_name_resource.id
