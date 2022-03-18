// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param storageAccountName string
param shareName string
param accessTier string = 'TransactionOptimized'
param enabledProtocols string = 'SMB'


resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = {
  name: '${storageAccountName}/default/${shareName}'
  properties: {
    accessTier: accessTier
    enabledProtocols: enabledProtocols
    metadata: {}
    shareQuota: 5120
  }
}
