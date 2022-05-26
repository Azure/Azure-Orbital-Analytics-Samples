// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param principalId string
param roleDefinitionId string

param batchAccountName string

param roleAssignmentId string = guid(principalId, roleDefinitionId, batchAccountName)

resource batchAccount 'Microsoft.Batch/batchAccounts@2021-06-01' existing = {
  name: batchAccountName
}

resource assignRole 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: roleAssignmentId
  scope: batchAccount
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
  }
}
