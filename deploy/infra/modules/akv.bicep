// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentName string
param keyVaultName string 
param location string = resourceGroup().location 
param skuName string = 'Standard'
param objIdForAccessPolicyPolicy string = ''
param usage string = 'general'

param certPermission array = [
  'get'
]
param keyPermission array = [
  'get'
]
param secretPermission array = [
  'get'
]
param storagePermission array = [
  'get'
]
param usePublicIp bool = true 
param publicNetworkAccess bool = true 
param enabledForDeployment bool = true
param enabledForDiskEncryption bool = true
param enabledForTemplateDeployment bool = true
param enablePurgeProtection bool = true
param enableRbacAuthorization bool = false
param enableSoftDelete bool = true
param softDeleteRetentionInDays int = 7

resource akv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  tags: {
    environment: environmentName  
    usage: usage
  }
  properties: {
    accessPolicies: [
      {
        objectId: !empty(objIdForAccessPolicyPolicy)? objIdForAccessPolicyPolicy : '${reference(resourceGroup().id, '2021-04-01', 'Full').subscriptionId}'
        permissions: {
          certificates: certPermission
          keys: keyPermission
          secrets: secretPermission
          storage: storagePermission
        }
        tenantId: subscription().tenantId
      }
    ]

    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: enableSoftDelete
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: (usePublicIp) ? 'Allow' : 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: (publicNetworkAccess) ? 'Enabled' : 'Disabled'
    sku: {
      family: 'A'
      name: skuName
    }
    softDeleteRetentionInDays: softDeleteRetentionInDays
    tenantId: subscription().tenantId
  }
}

output vaultUri string = akv.properties.vaultUri
