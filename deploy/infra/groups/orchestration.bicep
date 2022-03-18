// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// List of required parameters
param environmentCode string
param environmentTag string
param projectName string
param location string

// Name parameters for infrastructure resources
param orchestrationResourceGroupName string = ''
param keyvaultName string = ''
param batchAccountName string = ''
param batchAccountAutoStorageAccountName string = ''
param acrName string = ''
param uamiName string = ''

param pipelineResourceGroupName string = ''
param pipelineLinkedSvcKeyVaultName string = ''

// Mount options
param mountAccountName string
param mountAccountKey string
param mountFileUrl string

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

// Parameters with default values  for Batch Account
param batchAccountAllowedAuthenticationModes array = [
  'AAD'
  'SharedKey'
  'TaskAuthenticationToken'
]
param batchAccountAutoStorageAuthenticationMode string = 'StorageKeys'
param batchAccountPoolAllocationMode string = 'BatchService'
param batchAccountPublicNetworkAccess bool = true

// Parameters with default values  for Data Fetch Batch Account Pool
param batchAccountCpuOnlyPoolName string = 'data-cpu-pool'
param batchAccountCpuOnlyPoolVmSize string = 'standard_d2s_v3'
param batchAccountCpuOnlyPoolDedicatedNodes int = 5
param batchAccountCpuOnlyPoolImageReferencePublisher string = 'microsoft-azure-batch'
param batchAccountCpuOnlyPoolImageReferenceOffer string = 'ubuntu-server-container'
param batchAccountCpuOnlyPoolImageReferenceSku string = '20-04-lts'
param batchAccountCpuOnlyPoolImageReferenceVersion string = 'latest'
param batchAccountCpuOnlyPoolStartTaskCommandLine string = '/bin/bash -c "apt-get update && apt-get install -y python3-pip && pip install requests && pip install azure-storage-blob && pip install pandas"'

// Parameters with default values  for Postrgres Batch Account Pool
param batchAccountCpuGpuPoolName string = 'data-gpu-pool'
param batchAccountCpuGpuPoolVmSize string = 'standard_nv6'
param batchAccountCpuGpuPoolDedicatedNodes int = 3
param batchAccountCpuGpuPoolImageReferencePublisher string = 'microsoft-azure-batch'
param batchAccountCpuGpuPoolImageReferenceOffer string = 'ubuntu-server-container'
param batchAccountCpuGpuPoolImageReferenceSku string = '20-04-lts'
param batchAccountCpuGpuPoolImageReferenceVersion string = 'latest'
param batchAccountCpuGpuPoolStartTaskCommandLine string = '/bin/bash -c "apt-get update && apt-get install -y python3-pip && pip install azure-storage-blob && pip install psycopg2-binary"'


param batchLogsDiagCategories array = [
  'allLogs'
]
param batchMetricsDiagCategories array = [
  'AllMetrics'
]
param logAnalyticsWorkspaceId string

// Parameters with default values for ACR
param acrSku string = 'Standard'

var namingPrefix = '${environmentCode}-${projectName}'
var orchestrationResourceGroupNameVar = empty(orchestrationResourceGroupName) ? '${namingPrefix}-rg' : orchestrationResourceGroupName
var nameSuffix = substring(uniqueString(orchestrationResourceGroupNameVar), 0, 6)
var uamiNameVar = empty(uamiName) ? '${namingPrefix}-umi' : uamiName
var keyvaultNameVar = empty(keyvaultName) ? '${namingPrefix}-kv' : keyvaultName
var batchAccountNameVar = empty(batchAccountName) ? '${environmentCode}${projectName}batchact' : batchAccountName
var batchAccountAutoStorageAccountNameVar = empty(batchAccountAutoStorageAccountName) ? 'batchacc${nameSuffix}' : batchAccountAutoStorageAccountName
var acrNameVar = empty(acrName) ? '${environmentCode}${projectName}acr' : acrName

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

module batchAccountAutoStorageAccount '../modules/storage.bicep' = {
  name: '${namingPrefix}-batch-account-auto-storage'
  params: {
    storageAccountName: batchAccountAutoStorageAccountNameVar
    environmentName: environmentTag
    location: location
    storeType: 'batch'
  }
}

module batchStorageAccountCredentials '../modules/storage.credentials.to.keyvault.bicep' = {
  name: '${namingPrefix}-batch-storage-credentials'
  params: {
    environmentName: environmentTag
    storageAccountName: batchAccountAutoStorageAccountNameVar
    keyVaultName: keyvaultNameVar
    keyVaultResourceGroup: resourceGroup().name
    secretNamePrefix: 'Batch'
  }
  dependsOn: [
    keyVault
    batchAccountAutoStorageAccount
  ]
}

module uami '../modules/managed.identity.user.bicep' = {
  name: '${namingPrefix}-umi'
  params: {
    environmentName: environmentTag
    location: location
    uamiName: uamiNameVar
  }
}

module batchAccount '../modules/batch.account.bicep' = {
  name: '${namingPrefix}-batch-account'
  params: {
    environmentName: environmentTag
    location: location
    batchAccountName: toLower(batchAccountNameVar)
    userManagedIdentityId: uami.outputs.uamiId
    userManagedIdentityPrincipalId: uami.outputs.uamiPrincipalId
    allowedAuthenticationModes: batchAccountAllowedAuthenticationModes
    autoStorageAuthenticationMode: batchAccountAutoStorageAuthenticationMode
    autoStorageAccountName: batchAccountAutoStorageAccountNameVar
    poolAllocationMode: batchAccountPoolAllocationMode
    publicNetworkAccess: batchAccountPublicNetworkAccess
  }
  dependsOn: [
    uami
    batchAccountAutoStorageAccount
  ]
}

module batchAccountCpuOnlyPool '../modules/batch.account.pools.bicep' = {
  name: '${namingPrefix}-batch-account-data-fetch-pool'
  params: {
    batchAccountName: batchAccountNameVar
    batchAccountPoolName: batchAccountCpuOnlyPoolName
    vmSize: batchAccountCpuOnlyPoolVmSize
    fixedScaleTargetDedicatedNodes: batchAccountCpuOnlyPoolDedicatedNodes
    imageReferencePublisher: batchAccountCpuOnlyPoolImageReferencePublisher
    imageReferenceOffer: batchAccountCpuOnlyPoolImageReferenceOffer
    imageReferenceSku: batchAccountCpuOnlyPoolImageReferenceSku
    imageReferenceVersion: batchAccountCpuOnlyPoolImageReferenceVersion
    startTaskCommandLine: batchAccountCpuOnlyPoolStartTaskCommandLine
  }
  dependsOn: [
    batchAccountAutoStorageAccount
    batchAccount
  ]
}

module batchAccountCpuGpuPool '../modules/batch.account.pools.bicep' = {
  name: '${namingPrefix}-batch-account-postgres-pool'
  params: {
    batchAccountName: batchAccountNameVar
    batchAccountPoolName: batchAccountCpuGpuPoolName
    vmSize: batchAccountCpuGpuPoolVmSize
    fixedScaleTargetDedicatedNodes: batchAccountCpuGpuPoolDedicatedNodes
    imageReferencePublisher: batchAccountCpuGpuPoolImageReferencePublisher
    imageReferenceOffer: batchAccountCpuGpuPoolImageReferenceOffer
    imageReferenceSku: batchAccountCpuGpuPoolImageReferenceSku
    imageReferenceVersion: batchAccountCpuGpuPoolImageReferenceVersion
    startTaskCommandLine: batchAccountCpuGpuPoolStartTaskCommandLine
    azureFileShareConfigurationAccountKey: mountAccountKey
    azureFileShareConfigurationAccountName: mountAccountName
    azureFileShareConfigurationAzureFileUrl: mountFileUrl
    azureFileShareConfigurationMountOptions: '-o vers=3.0,dir_mode=0777,file_mode=0777,sec=ntlmssp'
    azureFileShareConfigurationRelativeMountPath: 'S'
  }
  dependsOn: [
    batchAccountAutoStorageAccount
    batchAccount
  ]
}

module acr '../modules/acr.bicep' = {
  name: '${namingPrefix}-acr'
  params: {
    environmentName: environmentTag
    location: location
    acrName: acrNameVar
    acrSku: acrSku
  }
}

module acrCredentials '../modules/acr.credentials.to.keyvault.bicep' = {
  name: '${namingPrefix}-acr-credentials'
  params: {
    environmentName: environmentTag
    acrName: acrNameVar
    keyVaultName: keyvaultNameVar

  }
  dependsOn: [
    keyVault
    acr
  ]
}

module batchAccountCredentials '../modules/batch.account.to.keyvault.bicep' = {
  name: '${namingPrefix}-batch-account-credentials'
  params: {
    environmentName: environmentTag
    batchAccoutName: toLower(batchAccountNameVar)
    keyVaultName: pipelineLinkedSvcKeyVaultName
    keyVaultResourceGroup: pipelineResourceGroupName
  }
  dependsOn: [
    keyVault
    batchAccount
  ]
}

module batchDiagnosticSettings '../modules/batch-diagnostic-settings.bicep' = {
  name: '${namingPrefix}-synapse-diag-settings'
  params: {
    batchAccountName: batchAccountNameVar
    logs: [for category in batchLogsDiagCategories: {
        category: null
        categoryGroup: category
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }]
    metrics: [for category in batchMetricsDiagCategories: {
        category: category
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
    }]
    workspaceId: logAnalyticsWorkspaceId
  }
  dependsOn: [
    batchAccount
  ]
}
