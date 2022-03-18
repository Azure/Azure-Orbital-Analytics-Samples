// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentName string
param storageAccountName string
param keyVaultName string
param keyVaultResourceGroup string
param secretNamePrefix string = 'Geospatial'
param utcValue string = utcNow()

var storageAccountNameSecretNameVar = '${secretNamePrefix}StorageAccountName'
var storageAccountKeySecretNameVar = '${secretNamePrefix}StorageAccountKey'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: storageAccountName
} 

module storageAccountNameSecret './akv.secrets.bicep' = {
  name: '${toLower(secretNamePrefix)}-storage-account-name-${utcValue}'
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    environmentName: environmentName
    keyVaultName: keyVaultName
    secretName: storageAccountNameSecretNameVar
    secretValue: storageAccount.name
  }
}

module storageAccountKeySecret './akv.secrets.bicep' = {
  name: '${toLower(secretNamePrefix)}-storage-account-key-${utcValue}'
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    environmentName: environmentName
    keyVaultName: keyVaultName
    secretName: storageAccountKeySecretNameVar
    secretValue: storageAccount.listKeys().keys[0].value
  }
}
