// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param storageAccountName string
param containerName string
param containerPublicAccess string = 'None'
param containerDeleteRetentionPolicyEnabled bool = true
param containerDeleteRetentionPolicyDays int = 7
param deleteRetentionPolicyEnabled bool = true
param deleteRetentionPolicyDays int = 7
param isVersioningEnabled bool = false


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: storageAccountName
}

resource storageAccountService 'Microsoft.Storage/storageAccounts/blobServices@2021-08-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    containerDeleteRetentionPolicy: {
      days: containerDeleteRetentionPolicyDays
      enabled: containerDeleteRetentionPolicyEnabled
    }
    deleteRetentionPolicy: {
      days: deleteRetentionPolicyDays
      enabled: deleteRetentionPolicyEnabled
    }
    isVersioningEnabled: isVersioningEnabled
  }
}

resource stgAcctBlobSvcsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: containerName
  parent: storageAccountService
  properties: {
    publicAccess: containerPublicAccess
  }
}

output containerId string = stgAcctBlobSvcsContainer.id
