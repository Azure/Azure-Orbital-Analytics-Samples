// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param storageAccountName string
param location string = resourceGroup().location
param environmentName string 
param storeType string = 'data'
param storageSku string = 'Standard_GRS'
param storageKind string = 'StorageV2'
param public_access string = 'Enabled'
param isHnsEnabled bool = false

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location 
  tags: {
    environment: environmentName
    store: storeType
  }
  sku: {
    name: storageSku
  }
  kind: storageKind
  properties:{
    isHnsEnabled: isHnsEnabled
    accessTier: 'Hot'
    publicNetworkAccess: public_access
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: ((public_access == 'Enabled')) ? 'Allow' : 'Deny'
    }
  }
}

output storageAccountId string = storageAccount.id
output fileEndpointUri string = storageAccount.properties.primaryEndpoints.file
output primaryKey string = storageAccount.listKeys().keys[0].value
