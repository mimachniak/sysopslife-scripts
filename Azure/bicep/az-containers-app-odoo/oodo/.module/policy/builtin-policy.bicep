
targetScope = 'managementGroup'

param policyAssignmentName string
param policyDefinitionID string
param policyParameters object = {}

resource assignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
    name: policyAssignmentName
    properties: {
        policyDefinitionId: policyDefinitionID
        parameters: !empty(policyParameters) ? policyParameters : null
        //parameters: policyParameters
    }
}
output assignmentId string = assignment.id
