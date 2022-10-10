// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// List of required parameters
param environmentCode string
param environmentTag string
param projectName string
param location string

// Name parameters for infrastructure resources
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

// Parameters for Postgres
param deployPgSQL bool = true
param serverName string = ''
param administratorLogin string = ''
param postgresAdminLoginPass string = '' 

// Parameters with default values for Postgres
param skuCapacity int = 2
param skuName string = 'GP_Gen5_2'
param skuSizeMB string = '51200'
param skuTier string = 'GeneralPurpose'
param skuFamily string = 'Gen5'
param postgresqlVersion string = '11'
param backupRetentionDays int = 7
param geoRedundantBackup string = 'Disabled'

param postgresAdminPasswordSecretName string = 'PostgresAdminPassword'
param utcValue string = utcNow()
var namingPrefix = '${environmentCode}-${projectName}'
var nameSuffix = substring(uniqueString(guid('${subscription().subscriptionId}${namingPrefix}${location}')), 0, 10)
var postgresAdminLoginPassVar = empty(postgresAdminLoginPass) ? '${uniqueString(resourceGroup().id)}!' : postgresAdminLoginPass
var administratorLoginVar = empty(administratorLogin) ? '${environmentCode}_admin_user' : administratorLogin
var serverNameVar = empty(serverName) ? 'pg${nameSuffix}' : serverName
param uamiName string = ''
var uamiNameVar = empty(uamiName) ? '${namingPrefix}${nameSuffix}-umi' : uamiName
var keyvaultNameVar = empty(keyvaultName) ? 'kvd${nameSuffix}' : keyvaultName
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

module synapseIdentityForStorageAccess '../modules/storage-role-assignment.bicep' = [ for (role, index) in synapseMIStorageAccountRoles: {
  name: '${namingPrefix}-synapse-id-kv-${index}'
  params: {
    resourceName: rawDataStorageAccountNameVar
    principalId: synapseMIPrincipalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${role}'
  }
  dependsOn: [
    rawDataStorageAccount
  ]
}]

module postgresqlServer '../modules/postgres.single.svc.bicep' = if(deployPgSQL) {
  name: '${namingPrefix}-postgres'
  params: {
    location: location
    serverName: serverNameVar
    administratorLogin: administratorLoginVar
    administratorLoginPassword: postgresAdminLoginPassVar
    skuCapacity: skuCapacity
    skuName: skuName
    skuSizeMB: skuSizeMB
    skuTier: skuTier
    skuFamily: skuFamily
    postgresqlVersion: postgresqlVersion
    backupRetentionDays: backupRetentionDays
    geoRedundantBackup: geoRedundantBackup
  }
}

resource postgresql_server_resource 'Microsoft.DBforPostgreSQL/servers@2017-12-01' existing = if(deployPgSQL) {
  name: serverNameVar
}

resource azurerm_postgresql_firewall_rule 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = if(deployPgSQL) {
  name: 'AllowAccessToAzureServices'
  parent: postgresql_server_resource
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
  dependsOn: [
    postgresqlServer
  ]
}
module dataUami '../modules/managed.identity.user.bicep' = {
  name: '${namingPrefix}-umi'
  params: {
    environmentName: environmentTag
    location: location
    uamiName: uamiNameVar
  }
}
module pgAdministratorLoginPassword '../modules/akv.secrets.bicep' = if(deployPgSQL) {
  name: 'pg-admin-login-pass-${utcValue}'
  scope: resourceGroup(pipelineResourceGroupName)
  params: {
    environmentName: environmentTag
    keyVaultName: pipelineLinkedSvcKeyVaultName
    secretName: postgresAdminPasswordSecretName
    secretValue: postgresAdminLoginPassVar
  }
  dependsOn: [
    postgresqlServer
  ]
}

module createContainerForTableCreation '../modules/aci.bicep' = if(deployPgSQL) {
  name: '${namingPrefix}-container-for-db-table-creation'
  params: {
    name: '${namingPrefix}-container'
    userManagedIdentityId: dataUami.outputs.uamiId
    userManagedIdentityPrincipalId: dataUami.outputs.uamiPrincipalId
    location: location
    server: deployPgSQL?postgresqlServer.outputs.pgServerName:''
    username: deployPgSQL?postgresqlServer.outputs.pgUserName:''
    dbPassword: deployPgSQL?postgresAdminLoginPassVar:''
  }
  dependsOn: [
    postgresqlServer
    azurerm_postgresql_firewall_rule
    dataUami
  ]
}

module deleteContainerForTableCreation '../modules/aci.delete.bicep' = if(deployPgSQL) {
  name: 'deleteContainerForTableCreation'
  params: {
    location: location
    aciName: '${namingPrefix}-container'
    uamiName: uamiNameVar
  }
  dependsOn: [
    createContainerForTableCreation
  ]
}

output rawStorageAccountName string = rawDataStorageAccountNameVar
output rawStorageFileEndpointUri string = rawDataStorageAccount.outputs.fileEndpointUri
output rawStoragePrimaryKey string = rawDataStorageAccount.outputs.primaryKey
