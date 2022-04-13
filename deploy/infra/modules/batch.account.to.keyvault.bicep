// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentName string
param batchAccoutName string
param keyVaultName string
param keyVaultResourceGroup string
param secretNamePrefix string = 'Geospatial'
param utcValue string = utcNow()

var batchAccountNameSecretNameVar = '${secretNamePrefix}BatchAccountKey'

resource batchAccount 'Microsoft.Batch/batchAccounts@2021-06-01' existing = {
  name: batchAccoutName
} 

module storageAccountNameSecret './akv.secrets.bicep' = {
  name: 'batch-account-key-${utcValue}'
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    environmentName: environmentName
    keyVaultName: keyVaultName
    secretName: batchAccountNameSecretNameVar
    secretValue: batchAccount.listKeys().primary
  }
}
