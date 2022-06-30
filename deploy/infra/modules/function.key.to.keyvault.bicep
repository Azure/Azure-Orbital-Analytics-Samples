// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentName string
param functionId string
param keyVaultName string
param functionSecretName string
param keyVaultResourceGroup string
param utcValue string = utcNow()

module functionKeySecret './akv.secrets.bicep' = {
  name: 'function-key-${utcValue}'
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    environmentName: environmentName
    keyVaultName: keyVaultName
    secretName: functionSecretName
    secretValue: listKeys(functionId, '2021-03-01').default
  }
}

