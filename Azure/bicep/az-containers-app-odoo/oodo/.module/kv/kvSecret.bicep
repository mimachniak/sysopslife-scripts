param kvSecretName string
param kvSecretValue string
param kvName string
param tags object

resource kvSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${kvName}/${kvSecretName}'
  tags: tags
  properties: {
    value: kvSecretValue
  }
}
