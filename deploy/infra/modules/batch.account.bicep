// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param location string = resourceGroup().location 
param environmentName string
param batchAccountName string
param userManagedIdentityId string
param type string = 'batch'
param allowedAuthenticationModes array = [
  'AAD'
  'SharedKey'
  'TaskAuthenticationToken'
]
param autoStorageAuthenticationMode string = 'StorageKeys'
param autoStorageAccountName string
param poolAllocationMode string = 'BatchService'
param publicNetworkAccess bool = true 
param assignRoleToUserManagedIdentity string = 'Owner'
param userManagedIdentityPrincipalId string

resource autoStorageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: autoStorageAccountName
} 

resource batchAccount 'Microsoft.Batch/batchAccounts@2021-06-01' = {
  name: batchAccountName
  location: location
  tags: {
    environment: environmentName
    type: type
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities : {
      '${userManagedIdentityId}': {}
    }
  }
  properties: {
    allowedAuthenticationModes: allowedAuthenticationModes
    autoStorage: {
      authenticationMode: autoStorageAuthenticationMode
      storageAccountId: autoStorageAccount.id
    }
    encryption: {
      keySource: 'Microsoft.Batch'
    }
    poolAllocationMode: poolAllocationMode
    publicNetworkAccess: (publicNetworkAccess) ? 'Enabled' : 'Disabled'
  }
}

var role = {
  owner: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  contributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  reader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

resource assignRole 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(batchAccount.id, userManagedIdentityPrincipalId, role[toLower(assignRoleToUserManagedIdentity)])
  scope: batchAccount
  properties: {
    principalId: userManagedIdentityPrincipalId
    roleDefinitionId: role[toLower(assignRoleToUserManagedIdentity)]
  }
}

output batchAccountId string = batchAccount.id
