// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentName string 
param location string = resourceGroup().location
param synapseWorkspaceName string
param hnsStorageAccountName string
param hnsStorageFileSystem string = 'users'
param sqlAdminLogin string = 'sqladmin'
param sqlAdminLoginPassword string
param firewallAllowEndIP string = '255.255.255.255'
param firewallAllowStartIP string = '0.0.0.0'

param gitRepoAccountName string = ''
param gitRepoCollaborationBranch string = 'main'
param gitRepoHostName string = ''
param gitRepoLastCommitId string = ''
param gitRepoVstsProjectName string = ''
param gitRepoRepositoryName string = ''
param gitRepoRootFolder string = '.'
param gitRepoVstsTenantId string = subscription().tenantId
param gitRepoType string = ''

param keyVaultName string = ''
param synapseSqlAdminPasswordSecretName string = 'synapse-sqladmin-password'
param utcValue string = utcNow()
param workspaceId string = 'default'

param createManagedVnet bool = false
@allowed([
  'default'
  ''
])
param managedVirtualNetwork string = 'default'
param preventDataExfiltration bool = false
param managedVirtualNetworkSettings object = {
  managedVirtualNetworkSettings : {
    allowedAadTenantIdsForLinking: []
    preventDataExfiltration: preventDataExfiltration
  }
  managedVirtualNetwork : managedVirtualNetwork
}

var defaultDataLakeStorageSettings = {
  resourceId: hnsStorage.id
  accountUrl: hnsStorage.properties.primaryEndpoints.dfs
  filesystem: hnsStorageFileSystem
  createManagedPrivateEndpoint: createManagedVnet
}

var synapseCommonProperties = {
  defaultDataLakeStorage: defaultDataLakeStorageSettings
  sqlAdministratorLogin: sqlAdminLogin
  sqlAdministratorLoginPassword: sqlAdminLoginPassword
  workspaceRepositoryConfiguration:(empty(gitRepoType))? {}: {
    accountName: gitRepoAccountName
    collaborationBranch: gitRepoCollaborationBranch
    hostName: gitRepoHostName
    lastCommitId: gitRepoLastCommitId
    projectName: gitRepoVstsProjectName
    repositoryName: gitRepoRepositoryName
    rootFolder: gitRepoRootFolder
    tenantId: gitRepoVstsTenantId
    type: gitRepoType
  }
}
var selectedSynapseProperties = createManagedVnet ? union(synapseCommonProperties, managedVirtualNetworkSettings) : synapseCommonProperties

resource hnsStorage 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: hnsStorageAccountName
}

resource synapseWorspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseWorkspaceName
  location: location
  tags: {
    environment: environmentName  
    workspaceId: workspaceId  
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: selectedSynapseProperties
}

resource synapseWorkspaceFwRules 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: 'allowAll'
  parent: synapseWorspace
  properties: {
    endIpAddress: firewallAllowEndIP
    startIpAddress: firewallAllowStartIP
  }
}

module synapseSqlAdminPasswordSecret './akv.secrets.bicep' = if (!empty(keyVaultName)) {
  name: 'synapse-sqladmin-password-${utcValue}'
  params: {
    environmentName: environmentName
    keyVaultName: keyVaultName
    secretName: synapseSqlAdminPasswordSecretName
    secretValue: sqlAdminLoginPassword
  }
}

output synapseMIPrincipalId string = synapseWorspace.identity.principalId
