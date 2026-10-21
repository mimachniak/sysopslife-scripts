using '../main.bicep'

// Test values for static analysis only. This file is never deployed; it exists so PSRule can
// compile the module to ARM and evaluate the WAF rules against a realistic configuration.

param par_rv_name = 'rsv-test-001'

// Exercises par_tags so Azure.Resource.UseTags checks that the module actually applies tags
// to the resource. Keys follow the convention used in bicep/.
param par_tags = {
  Environment: 'Test'
  CostCenter: 'IT'
}
