// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentCode string
param projectName string

// Name parameters for infrastructure resources
param batchAccountName string
param batchAccountResourceGroup string
param batchAccountPoolCheckUamiName string = ''
param batchAccountLocation string = resourceGroup().location

// Mount options
param batchAccountPoolMountAccountName string
param batchAccountPoolMountAccountKey string
param batchAccountPoolMountFileUrl string

// ACR information
param acrName string = ''

// Parameters with default values  for Data Fetch Batch Account Pool
param batchAccountCpuOnlyPoolName string = 'data-cpu-pool'
param batchAccountCpuOnlyPoolVmSize string = 'standard_d2s_v3'
param batchAccountCpuOnlyPoolDedicatedNodes int = 1
param batchAccountCpuOnlyPoolImageReferencePublisher string = 'microsoft-azure-batch'
param batchAccountCpuOnlyPoolImageReferenceOffer string = 'ubuntu-server-container'
param batchAccountCpuOnlyPoolImageReferenceSku string = '20-04-lts'
param batchAccountCpuOnlyPoolImageReferenceVersion string = 'latest'

var namingPrefix = '${environmentCode}-${projectName}'

resource batchAccount 'Microsoft.Batch/batchAccounts@2021-06-01' existing = {
  name: batchAccountName
  scope: resourceGroup(batchAccountResourceGroup)
}

resource containerRepository 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = if (acrName != '') {
  name: acrName
}

module batchAccountPoolCheck 'modules/batch.account.pool.exists.bicep' = {
  name: '${namingPrefix}-batch-account-pool-exists'
  scope: resourceGroup(batchAccountResourceGroup)
  params: {
    batchAccountName: batchAccountName
    batchPoolName: batchAccountCpuOnlyPoolName
    userManagedIdentityName: batchAccountPoolCheckUamiName==''?'${namingPrefix}-umi':batchAccountPoolCheckUamiName
    userManagedIdentityResourcegroupName: resourceGroup().name
    location: batchAccountLocation
  }
  dependsOn: [
    batchAccount
  ]
}

module batchAccountCpuOnlyPool 'modules/batch.account.pools.bicep' = {
  name: '${namingPrefix}-batch-account-data-fetch-pool'
  scope: resourceGroup(batchAccountResourceGroup)
  params: {
    batchAccountName: batchAccountName
    batchAccountPoolName: batchAccountCpuOnlyPoolName
    vmSize: batchAccountCpuOnlyPoolVmSize
    fixedScaleTargetDedicatedNodes: batchAccountCpuOnlyPoolDedicatedNodes
    imageReferencePublisher: batchAccountCpuOnlyPoolImageReferencePublisher
    imageReferenceOffer: batchAccountCpuOnlyPoolImageReferenceOffer
    imageReferenceSku: batchAccountCpuOnlyPoolImageReferenceSku
    imageReferenceVersion: batchAccountCpuOnlyPoolImageReferenceVersion
    azureFileShareConfigurationAccountKey: batchAccountPoolMountAccountKey
    azureFileShareConfigurationAccountName: batchAccountPoolMountAccountName
    azureFileShareConfigurationAzureFileUrl: batchAccountPoolMountFileUrl
    azureFileShareConfigurationMountOptions: '-o vers=3.0,dir_mode=0777,file_mode=0777,sec=ntlmssp'
    azureFileShareConfigurationRelativeMountPath: 'S'
    containerRegistryServer: containerRepository.properties.loginServer
    containerRegistryUsername: containerRepository.listCredentials().username
    containerRegistryPassword: containerRepository.listCredentials().passwords[0].value
    batchPoolExists: batchAccountPoolCheck.outputs.batchPoolExists
  }
  dependsOn: [
    containerRepository
    batchAccount
    batchAccountPoolCheck
  ]
}
