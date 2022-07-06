// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

targetScope='subscription'

@description('Location for all the resources to be deployed')
param location string

@minLength(3)
@maxLength(9)
@description('Prefix to be used for naming all the resources in the deployment')
param environmentCode string

@description('Environment will be used as Tag on the resource group')
param environment string

@description('Used for naming of the network resource group and its resources')
param networkModulePrefix string = 'network'

@description('Used for naming of the data resource group and its resources')
param dataModulePrefix string = 'data'

@description('Used for naming of the monitor resource group and its resources')
param monitorModulePrefix string = 'monitor'

@description('Used for naming of the pipeline resource group and its resources')
param pipelineModulePrefix string = 'pipeline'

@description('Used for naming of the orchestration resource group and its resources')
param orchestrationModulePrefix string = 'orc'

@description('Specify whether or not to deploy PostgreSQL')
param deployPgSQL bool = true

@description('Postgres DB administrator login password')
@secure()
param postgresAdminLoginPass string

@description('Specify whether or not to deploy AI model execution infrastructure')
param deployAiModelInfra bool = true

@description('Specify which AI model execution infrastructure is used, valid choices are aks, batch-account')
@allowed([
  'batch-account'
  'aks'
])
param aiModelInfraType string = 'batch-account'

var networkResourceGroupName = '${environmentCode}-${networkModulePrefix}-rg'
var dataResourceGroupName = '${environmentCode}-${dataModulePrefix}-rg'
var monitorResourceGroupName = '${environmentCode}-${monitorModulePrefix}-rg'
var pipelineResourceGroupName = '${environmentCode}-${pipelineModulePrefix}-rg'
var orchestrationResourceGroupName = '${environmentCode}-${orchestrationModulePrefix}-rg'

module networkResourceGroup 'modules/resourcegroup.bicep' = {
  name : networkResourceGroupName
  scope: subscription()
  params: {
    environmentName: environment
    resourceGroupName: networkResourceGroupName
    resourceGroupLocation: location
  }
}

module networkModule 'groups/networking.bicep' = {
  name: '${networkModulePrefix}-module'
  scope: resourceGroup(networkResourceGroup.name)
  params: {
    projectName: networkModulePrefix
    Location: location
    environmentCode: environmentCode
    environmentTag: environment
    virtualNetworkName: '${environmentCode}-vnet'
  }
  dependsOn: [
    networkResourceGroup
  ]
}

module monitorResourceGroup 'modules/resourcegroup.bicep' = {
  name : monitorResourceGroupName
  scope: subscription()
  params: {
    environmentName: environment
    resourceGroupName: monitorResourceGroupName
    resourceGroupLocation: location
  }
}

module monitorModule 'groups/monitoring.bicep' = {
  name: '${monitorModulePrefix}-module'
  scope: resourceGroup(monitorResourceGroup.name)
  params: {
    projectName: monitorModulePrefix
    location: location
    environmentCode: environmentCode
    environmentTag: environment
  }
  dependsOn: [
    networkModule
  ]
}

module pipelineResourceGroup 'modules/resourcegroup.bicep' = {
  name : pipelineResourceGroupName
  scope: subscription()
  params: {
    environmentName: environment
    resourceGroupName: pipelineResourceGroupName
    resourceGroupLocation: location
  }
}

module pipelineModule 'groups/pipeline.bicep' = {
  name: '${pipelineModulePrefix}-module'
  scope: resourceGroup(pipelineResourceGroup.name)
  params: {
    projectName: pipelineModulePrefix
    location: location
    environmentCode: environmentCode
    environmentTag: environment
    logAnalyticsWorkspaceId: monitorModule.outputs.workspaceId
  }
  dependsOn: [
    networkModule
    monitorModule
  ]
}

module dataResourceGroup 'modules/resourcegroup.bicep' = {
  name : dataResourceGroupName
  scope: subscription()
  params: {
    environmentName: environment
    resourceGroupName: dataResourceGroupName
    resourceGroupLocation: location
  }
}

module dataModule 'groups/data.bicep' = {
  name: '${dataModulePrefix}-module'
  scope: resourceGroup(dataResourceGroup.name)
  params: {
    projectName: dataModulePrefix
    location: location
    environmentCode: environmentCode
    environmentTag: environment
    synapseMIPrincipalId: pipelineModule.outputs.synapseMIPrincipalId
    pipelineResourceGroupName: pipelineResourceGroup.name
    pipelineLinkedSvcKeyVaultName: '${environmentCode}-${pipelineModulePrefix}-kv'
    deployPgSQL: deployPgSQL
    postgresAdminLoginPass: postgresAdminLoginPass
  }
  dependsOn: [
    networkModule
    pipelineModule
  ]
}

module orchestrationResourceGroup 'modules/resourcegroup.bicep' = {
  name : orchestrationResourceGroupName
  scope: subscription()
  params: {
    environmentName: environment
    resourceGroupName: orchestrationResourceGroupName
    resourceGroupLocation: location
  }
}

module orchestrationModule 'groups/orchestration.bicep' = {
  name: '${orchestrationModulePrefix}-module'
  scope: resourceGroup(orchestrationResourceGroup.name)
  params: {
    projectName: orchestrationModulePrefix
    location: location
    environmentCode: environmentCode
    environmentTag: environment
    logAnalyticsWorkspaceId: monitorModule.outputs.workspaceId
    appInsightsInstrumentationKey: monitorModule.outputs.appInsightsInstrumentationKey
    mountAccountKey: dataModule.outputs.rawStoragePrimaryKey
    deployAiModelInfra: deployAiModelInfra
    aiModelInfraType: aiModelInfraType
    mountAccountName: dataModule.outputs.rawStorageAccountName
    mountFileUrl: '${dataModule.outputs.rawStorageFileEndpointUri}volume-a'
    pipelineResourceGroupName: pipelineResourceGroup.name
    pipelineLinkedSvcKeyVaultName: '${environmentCode}-${pipelineModulePrefix}-kv'
    synapseMIPrincipalId: pipelineModule.outputs.synapseMIPrincipalId
  }
  dependsOn: [
    pipelineModule
    networkModule
    monitorModule
  ]
}
