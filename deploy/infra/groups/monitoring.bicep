// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// List of required parameters
param environmentCode string
param environmentTag string
param projectName string
param location string

// Parameters with default values for Monitoring
var namingPrefix = '${environmentCode}-${projectName}'

module workspace '../modules/log-analytics.bicep' = {
  name : '${namingPrefix}-workspace'
  params: {
    environmentName: environmentTag
    workspaceName: '${namingPrefix}-workspace'
    location: location
  }
}

module appinsights '../modules/appinsights.bicep' = {
  name : '${namingPrefix}-appinsights' 
  params: {
    environmentName: environmentTag
    applicationInsightsName: '${namingPrefix}-appinsights'
    location: location
    workspaceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.OperationalInsights/workspaces/${namingPrefix}-workspace'
  }
  dependsOn: [
    workspace
  ]
}

output workspaceId string = workspace.outputs.workspaceId
