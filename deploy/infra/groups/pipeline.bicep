// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// List of required parameters
param environmentCode string
param environmentTag string
param projectName string
param location string

// Name parameters for infrastructure resources
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
param synapseAutoScaleMinNodeCount int = 3
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

// Parameters with default values for Synapse and its Managed Identity
param synapseMIStorageAccountRoles array = [
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
]

param logAnalyticsWorkspaceId string

var namingPrefix = '${environmentCode}-${projectName}'
var nameSuffix = substring(uniqueString(guid('${subscription().subscriptionId}${namingPrefix}${location}')), 0, 10)
var keyvaultNameVar = empty(keyvaultName) ? 'kvp${nameSuffix}' : keyvaultName
var synapseHnsStorageAccountNameVar = empty(synapseHnsStorageAccountName) ? 'synhns${nameSuffix}' : synapseHnsStorageAccountName
var synapseWorkspaceNameVar = empty(synapseWorkspaceName) ? 'synws${nameSuffix}' : synapseWorkspaceName
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

module synapseIdentityForStorageAccess '../modules/storage-role-assignment.bicep' = [ for (role, roleIndex) in synapseMIStorageAccountRoles: {
  name: '${namingPrefix}-synapse-id-kv-${roleIndex}'
  params: {
    resourceName: synapseHnsStorageAccountNameVar
    principalId: synapseWorkspace.outputs.synapseMIPrincipalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${role}'
  }
  dependsOn: [
    synapseHnsStorageAccount
    synapseWorkspace
  ]
}]

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
output pipelineLinkedSvcKeyVaultName string = keyvaultNameVar
