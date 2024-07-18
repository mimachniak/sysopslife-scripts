targetScope = 'tenant'

@description('Display Name of Top level Managment Group')
param par_managemnt_group_display_name string

@description('Id of parent Managment Group')
param par_managemnt_group_parent string

resource res_top_level_mg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: par_managemnt_group_display_name
  properties: {
    details: {
      parent: {
        id: par_managemnt_group_parent
      }
    }
    displayName: par_managemnt_group_display_name
    }
}

output out_top_mg_id string = res_top_level_mg.id
