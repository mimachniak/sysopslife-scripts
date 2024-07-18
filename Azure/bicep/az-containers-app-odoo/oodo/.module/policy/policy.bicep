
targetScope = 'managementGroup'

param policyAssignmentName string = 'Audit machines with insecure password security settings'
param policyDefinitionID string = '/providers/Microsoft.Authorization/policySetDefinitions/095e4ed9-c835-4ab6-9439-b5644362a06c'
resource assignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
    name: policyAssignmentName
    properties: {
        policyDefinitionId: policyDefinitionID
    }
}
output assignmentId string = assignment.id
