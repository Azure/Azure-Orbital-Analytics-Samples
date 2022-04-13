// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param storageAccountName string
param location string = resourceGroup().location
param environmentName string 
param storeType string = 'data'
param storageSku string = 'Standard_GRS'
param storageKind string = 'StorageV2'
param public_access string = 'Enabled'


module hnsEnabledStorageAccount 'storage.bicep' = {
  name: '${storageAccountName}-hns'
  params: {
    storageAccountName: storageAccountName
    location: location 
    environmentName: environmentName
    storageSku: storageSku
    storageKind: storageKind
    isHnsEnabled: true
    public_access: public_access
    storeType: storeType
  }
}

output storageAccountId string = hnsEnabledStorageAccount.outputs.storageAccountId
