// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param keyVaultName string 
param policyOps string
param objIdForPolicy string = ''  
param certPermission array = [
  'Get'
  'List'
  'Update'
  'Create'
  'Import'
  'Delete'
  'Recover'
  'Backup'
  'Restore'
  'ManageContacts'
  'ManageIssuers'
  'GetIssuers'
  'ListIssuers'
  'SetIssuers'
  'DeleteIssuers'
]
param keyPermission array = [
  'Get'
  'List'
  'Update'
  'Create'
  'Import'
  'Delete'
  'Recover'
  'Backup'
  'Restore'
]
param secretPermission array = [
  'Get'
  'List'
  'Set'
  'Delete'
  'Recover'
  'Backup'
  'Restore'
]

resource akv 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

resource akvAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-11-01-preview' = {
  name: policyOps
  parent: akv
  properties: {
    accessPolicies: [
      {
        applicationId: null
        objectId: objIdForPolicy
        permissions: {
          certificates: certPermission
          keys: keyPermission
          secrets: secretPermission
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}
