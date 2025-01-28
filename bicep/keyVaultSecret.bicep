param keyVaultName string
param secretName string

@secure()
param secretValue string

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${keyVaultName}/${secretName}' 
  properties: {
    value: secretValue
  }
}

output keyVaultSecretUri string = keyVaultSecret.properties.secretUri
