// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentName string
param keyVaultName string 
param secretName string
param secretValue string 

resource akv 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

resource akvSecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: secretName
  parent: akv
  properties: {
    value: secretValue
  }
  tags: {
    environment: environmentName    
  }
} 
