param privateEndpointName string
param subnetid object
param privateLinkServiceConnections array
param tags object

resource res_private_Endpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: privateEndpointName
  location: resourceGroup().location
  tags: tags
  properties: {
    subnet: subnetid
    privateLinkServiceConnections: privateLinkServiceConnections
  }
}

output out_private_endpoint_name string = res_private_Endpoint.name
