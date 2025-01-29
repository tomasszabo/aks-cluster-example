
param location string
param prefix string

param storageAccountName string = '${prefix}sa${uniqueString(resourceGroup().id)}'

param fileShares array = [
  'config-store'
  'metrisfileserver'
  'metrisrepository'
]

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: {
    customer: 'customer1'
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Enabled'
    allowBlobPublicAccess: true
  }
}

resource shares 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  
  resource fileShare 'shares@2023-05-01' = [for fileShareName in fileShares: {
    name: fileShareName
    properties: {
      shareQuota: 20 // Quota in GB
      accessTier: 'TransactionOptimized'
    }
  }]
}


output storageAccountName string = storageAccountName
output storageAccountId string = storageAccount.id
