// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// List of required parameters
param environmentCode string
param environmentTag string
param projectName string
param location string

// Name parameters for infrastructure resources
param dataResourceGroupName string = ''
param pipelineResourceGroupName string = ''
param pipelineLinkedSvcKeyVaultName string = ''
param keyvaultName string = ''
param rawDataStorageAccountName string = ''

// Parameters with default values for Keyvault
param keyvaultSkuName string = 'Standard'
param objIdForKeyvaultAccessPolicyPolicy string = ''
param keyvaultCertPermission array = [
  'All'
]
param keyvaultKeyPermission array = [
  'All'
]
param keyvaultSecretPermission array = [
  'All'
]
param keyvaultStoragePermission array = [
  'All'
]
param keyvaultUsePublicIp bool = true
param keyvaultPublicNetworkAccess bool = true
param keyvaultEnabledForDeployment bool = true
param keyvaultEnabledForDiskEncryption bool = true
param keyvaultEnabledForTemplateDeployment bool = true
param keyvaultEnablePurgeProtection bool = true
param keyvaultEnableRbacAuthorization bool = false
param keyvaultEnableSoftDelete bool = true
param keyvaultSoftDeleteRetentionInDays int = 7

// Parameters with default values for Synapse and its Managed Identity
param synapseMIStorageAccountRoles array = [
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
]
param synapseMIPrincipalId string = ''

var namingPrefix = '${environmentCode}-${projectName}'
var dataResourceGroupNameVar = empty(dataResourceGroupName) ? '${namingPrefix}-rg' : dataResourceGroupName
var nameSuffix = substring(uniqueString(dataResourceGroupNameVar), 0, 6)
var keyvaultNameVar = empty(keyvaultName) ? '${namingPrefix}-kv' : keyvaultName
var rawDataStorageAccountNameVar = empty(rawDataStorageAccountName) ? 'rawdata${nameSuffix}' : rawDataStorageAccountName

module keyVault '../modules/akv.bicep' = {
  name: '${namingPrefix}-akv'
  params: {
    environmentName: environmentTag
    keyVaultName: keyvaultNameVar
    location: location
    skuName:keyvaultSkuName
    objIdForAccessPolicyPolicy: objIdForKeyvaultAccessPolicyPolicy
    certPermission:keyvaultCertPermission
    keyPermission:keyvaultKeyPermission
    secretPermission:keyvaultSecretPermission
    storagePermission:keyvaultStoragePermission
    usePublicIp: keyvaultUsePublicIp
    publicNetworkAccess:keyvaultPublicNetworkAccess
    enabledForDeployment: keyvaultEnabledForDeployment
    enabledForDiskEncryption: keyvaultEnabledForDiskEncryption
    enabledForTemplateDeployment: keyvaultEnabledForTemplateDeployment
    enablePurgeProtection: keyvaultEnablePurgeProtection
    enableRbacAuthorization: keyvaultEnableRbacAuthorization
    enableSoftDelete: keyvaultEnableSoftDelete
    softDeleteRetentionInDays: keyvaultSoftDeleteRetentionInDays
  }
}

module rawDataStorageAccount '../modules/storage.bicep' = {
  name: '${namingPrefix}-raw-data-storage'
  params: {
    storageAccountName: rawDataStorageAccountNameVar
    environmentName: environmentTag
    location: location
    isHnsEnabled: true
    storeType: 'raw'
  }
}

module rawDataStorageAccountFileShare '../modules/file-share.bicep' = {
  name: '${namingPrefix}-raw-data-storage-fileshare'
  params: {
    storageAccountName: rawDataStorageAccountNameVar
    shareName: 'volume-a'
  }
  dependsOn: [
    rawDataStorageAccount
  ]
}

module rawDataStorageAccountCredentials '../modules/storage.credentials.to.keyvault.bicep' = {
  name: '${namingPrefix}-raw-data-storage-credentials'
  params: {
    environmentName: environmentTag
    storageAccountName: rawDataStorageAccountNameVar
    keyVaultName: pipelineLinkedSvcKeyVaultName
    keyVaultResourceGroup: pipelineResourceGroupName
  }
  dependsOn: [
    rawDataStorageAccount
  ]
}

module synapseIdentityForStorageAccess '../modules/storage-role-assignment.bicep' = [ for role in synapseMIStorageAccountRoles: {
  name: '${namingPrefix}-synapse-id-kv-${role}'
  params: {
    resourceName: rawDataStorageAccountNameVar
    principalId: synapseMIPrincipalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${role}'
  }
  dependsOn: [
    rawDataStorageAccount
  ]
}]

output rawStorageAccountName string = rawDataStorageAccountNameVar
output rawStorageFileEndpointUri string = rawDataStorageAccount.outputs.fileEndpointUri
output rawStoragePrimaryKey string = rawDataStorageAccount.outputs.primaryKey

