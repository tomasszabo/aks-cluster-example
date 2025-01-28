
param location string
param prefix string

param storageAccountName string = '${prefix}sa${uniqueString(resourceGroup().id)}'
param storageAccountCustomer1Name string = '${prefix}sac1${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource storageAccountCustomer1 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountCustomer1Name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

output storageAccountName string = storageAccountName
output storageAccountCustomer1Name string = storageAccountCustomer1Name
output storageAccountId string = storageAccount.id
output storageAccountCustomer1Id string = storageAccountCustomer1.id
