// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param batchAccountName string

param logs array
param metrics array
param storageAccountId string = ''
param workspaceId string = ''
param serviceBusId string = ''

param logAnalyticsDestinationType string = ''
param eventHubAuthorizationRuleId string = ''
param eventHubName string = ''

resource existingResource 'Microsoft.Batch/batchAccounts@2021-06-01' existing = {
  name: batchAccountName
}

resource symbolicname 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${existingResource.name}-diag'
  scope: existingResource
  properties: {
    eventHubAuthorizationRuleId: empty(eventHubAuthorizationRuleId) ? null : eventHubAuthorizationRuleId
    eventHubName: empty(eventHubName) ? null : eventHubName
    logAnalyticsDestinationType: empty(logAnalyticsDestinationType) ? null: logAnalyticsDestinationType
    logs: logs
    metrics: metrics
    serviceBusRuleId: empty(serviceBusId) ? null : serviceBusId
    storageAccountId: empty(storageAccountId) ? null : storageAccountId
    workspaceId: empty(workspaceId) ? null : workspaceId
  }
}
