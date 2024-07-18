@description('Enter the name used to identify this resource and is displayed in the Power BI admin portal and Azure portal. The name must be unique in the selected location. Only lowercase letters and numbers may be used.')
param par_pbi_name string

@allowed([
  'A1'
  'A2'
  'A3'
  'A4'
  'A5'
  'A6'
  'A7'
  'A8'
])
@description('Select the resource size that best meets your needs')
param par_pbi_sku string = 'A1'
param par_tags object

@allowed([
  'Gen2'
  'Gen1'
])
param par_pbi_mode string = 'Gen2'

@description('The Power BI capacity administrator will manage the capacity in Power BI. The capacity administrator must be a member user or a service principal in your AAD tenant')
param par_pbi_admin array


resource res_pbi_dedicated 'Microsoft.PowerBIDedicated/capacities@2021-01-01' = {
  name: par_pbi_name
  location: resourceGroup().location
  tags: par_tags
  sku: {
    name: par_pbi_sku
  }
  properties: {
    mode: par_pbi_mode
    administration: {
      members: par_pbi_admin
    }
  }
}
