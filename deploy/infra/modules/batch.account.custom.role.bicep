// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

targetScope = 'subscription'

param batchAccountName string
param allowedActions array = [
  'Microsoft.Batch/batchAccounts/pools/write'
  'Microsoft.Batch/batchAccounts/pools/read'
  'Microsoft.Batch/batchAccounts/pools/delete'
  'Microsoft.Batch/batchAccounts/read'
  'Microsoft.Batch/batchAccounts/listKeys/action'
]
param allowedDataActions array = [
  'Microsoft.Batch/batchAccounts/jobSchedules/write'
  'Microsoft.Batch/batchAccounts/jobSchedules/delete'
  'Microsoft.Batch/batchAccounts/jobSchedules/read'
  'Microsoft.Batch/batchAccounts/jobs/write'
  'Microsoft.Batch/batchAccounts/jobs/delete'
  'Microsoft.Batch/batchAccounts/jobs/read'
]
param deniedActions array = []
param deniedDataActions array = []

module batchAccountCustomRole './custom.role.bicep' = {
  name: 'custom-role-for-${batchAccountName}'
  params: {
    roleName: 'custom-role-for-${batchAccountName}'
    roleDescription: 'Custom Role for Accessing Batch Accounts'
    allowedActions: allowedActions
    allowedDataActions: allowedDataActions
    deniedActions: deniedActions
    deniedDataActions: deniedDataActions
  }
}

output batchAccountCustomRoleName string = batchAccountCustomRole.outputs.customRoleID
