// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// List of required parameters
param environmentCode string
param environmentTag string
param projectName string
param location string

// Name parameters for infrastructure resources
param synapseResourceGroupName string = ''
param keyvaultName string = ''
param synapseHnsStorageAccountName string = ''
param synapseWorkspaceName string = ''
param synapseSparkPoolName string = ''
param synapseSqlAdminLoginPassword string = ''

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

// Parameters with default values  for Synapse Workspace
param synapseHnsStorageAccountFileSystem string = 'users'
param synapseSqlAdminLogin string = 'sqladmin'
param synapseFirewallAllowEndIP string = '255.255.255.255'
param synapseFirewallAllowStartIP string = '0.0.0.0'
param synapseAutoPauseEnabled bool = true
param synapseAutoPauseDelayInMinutes int = 15
param synapseAutoScaleEnabled bool = true
param synapseAutoScaleMinNodeCount int = 1
param synapseAutoScaleMaxNodeCount int = 5
param synapseCacheSize int = 0
param synapseDynamicExecutorAllocationEnabled bool = false
param synapseIsComputeIsolationEnabled bool = false
param synapseNodeCount int = 0
param synapseNodeSize string = 'Medium'
param synapseNodeSizeFamily string = 'MemoryOptimized'
param synapseSparkVersion string = '3.1'
param synapseGitRepoAccountName string = ''
param synapseGitRepoCollaborationBranch string = 'main'
param synapseGitRepoHostName string = ''
param synapseGitRepoLastCommitId string = ''
param synapseGitRepoVstsProjectName string = ''
param synapseGitRepoRepositoryName string = ''
param synapseGitRepoRootFolder string = '.'
param synapseGitRepoVstsTenantId string = subscription().tenantId
param synapseGitRepoType string = ''

param synapseCategories array = [
  'SynapseRbacOperations'
  'GatewayApiRequests'
  'SQLSecurityAuditEvents'
  'BuiltinSqlReqsEnded'
  'IntegrationPipelineRuns'
  'IntegrationActivityRuns'
  'IntegrationTriggerRuns'
]

param logAnalyticsWorkspaceId string

var namingPrefix = '${environmentCode}-${projectName}'
var synapseResourceGroupNameVar = empty(synapseResourceGroupName) ? '${namingPrefix}-rg' : synapseResourceGroupName
var nameSuffix = substring(uniqueString(synapseResourceGroupNameVar), 0, 6)
var keyvaultNameVar = empty(keyvaultName) ? '${namingPrefix}-kv' : keyvaultName
var synapseHnsStorageAccountNameVar = empty(synapseHnsStorageAccountName) ? 'synhns${nameSuffix}' : synapseHnsStorageAccountName
var synapseWorkspaceNameVar = empty(synapseWorkspaceName) ? '${namingPrefix}-syn-ws' : synapseWorkspaceName
var synapseSparkPoolNameVar = empty(synapseSparkPoolName) ? 'pool${nameSuffix}' : synapseSparkPoolName
var synapseSqlAdminLoginPasswordVar = empty(synapseSqlAdminLoginPassword) ? 'SynapsePassword!${nameSuffix}' : synapseSqlAdminLoginPassword

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
    usage: 'linkedService'
  }
}

module synapseHnsStorageAccount '../modules/storage.hns.bicep' = {
  name: '${namingPrefix}-hns-storage'
  params: {
    storageAccountName: synapseHnsStorageAccountNameVar
    environmentName: environmentTag
    location: location
    storeType: 'synapse'
  }
}

module synapseWorkspace '../modules/synapse.workspace.bicep' = {
  name: '${namingPrefix}-workspace'
  params:{
    environmentName: environmentTag
    location: location
    synapseWorkspaceName: synapseWorkspaceNameVar
    hnsStorageAccountName: synapseHnsStorageAccountNameVar
    hnsStorageFileSystem: synapseHnsStorageAccountFileSystem
    sqlAdminLogin: synapseSqlAdminLogin
    sqlAdminLoginPassword: synapseSqlAdminLoginPasswordVar
    firewallAllowEndIP: synapseFirewallAllowEndIP
    firewallAllowStartIP: synapseFirewallAllowStartIP
    keyVaultName: keyvaultName
    gitRepoAccountName: synapseGitRepoAccountName
    gitRepoCollaborationBranch: synapseGitRepoCollaborationBranch
    gitRepoHostName: synapseGitRepoHostName
    gitRepoLastCommitId: synapseGitRepoLastCommitId
    gitRepoVstsProjectName: synapseGitRepoVstsProjectName
    gitRepoRepositoryName: synapseGitRepoRepositoryName
    gitRepoRootFolder: synapseGitRepoRootFolder
    gitRepoVstsTenantId: synapseGitRepoVstsTenantId
    gitRepoType: synapseGitRepoType
  }
  dependsOn: [
    synapseHnsStorageAccount
    keyVault
  ]
}

module synapseIdentityKeyVaultAccess '../modules/akv.policy.bicep' = {
  name: '${namingPrefix}-synapse-id-kv'
  params: {
    keyVaultName: keyvaultNameVar
    policyOps: 'add'
    objIdForPolicy: synapseWorkspace.outputs.synapseMIPrincipalId
  }

  dependsOn: [
    synapseWorkspace
  ]
}

module synapseSparkPool '../modules/synapse.sparkpool.bicep' = {
  name: '${namingPrefix}-sparkpool'
  params:{
    environmentName: environmentTag
    location: location
    synapseWorkspaceName: synapseWorkspaceNameVar
    sparkPoolName: synapseSparkPoolNameVar
    autoPauseEnabled: synapseAutoPauseEnabled
    autoPauseDelayInMinutes: synapseAutoPauseDelayInMinutes
    autoScaleEnabled: synapseAutoScaleEnabled
    autoScaleMinNodeCount: synapseAutoScaleMinNodeCount
    autoScaleMaxNodeCount: synapseAutoScaleMaxNodeCount
    cacheSize: synapseCacheSize
    dynamicExecutorAllocationEnabled: synapseDynamicExecutorAllocationEnabled
    isComputeIsolationEnabled: synapseIsComputeIsolationEnabled
    nodeCount: synapseNodeCount
    nodeSize: synapseNodeSize
    nodeSizeFamily: synapseNodeSizeFamily
    sparkVersion: synapseSparkVersion
  }
  dependsOn: [
    synapseHnsStorageAccount
    synapseWorkspace
  ]
}

module synapseDiagnosticSettings '../modules/synapse-diagnostic-settings.bicep' = {
  name: '${namingPrefix}-synapse-diag-settings'
  params: {
    synapseWorkspaceName: synapseWorkspaceNameVar
    logs: [for category in synapseCategories: {
        category: category
        categoryGroup: null
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }]
      workspaceId: logAnalyticsWorkspaceId
  }
  dependsOn: [
    synapseWorkspace
  ]
}

module pkgDataStorageAccountCredentials '../modules/storage.credentials.to.keyvault.bicep' = {
  name: '${namingPrefix}-pkgs-storage-credentials'
  params: {
    environmentName: environmentTag
    storageAccountName: synapseHnsStorageAccountNameVar
    keyVaultName: keyvaultNameVar
    keyVaultResourceGroup: resourceGroup().name
    secretNamePrefix: 'Packages'
  }
  dependsOn: [
    keyVault
    synapseHnsStorageAccount
  ]
}

output synapseMIPrincipalId string = synapseWorkspace.outputs.synapseMIPrincipalId
