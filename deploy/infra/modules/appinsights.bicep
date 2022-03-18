// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param applicationInsightsName string
param location string
param workspaceId string
param appInsightsKind string = 'web'
param appInsightsType string = 'web'

resource applicationInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: applicationInsightsName
  location: location
  kind: appInsightsKind
  properties: {
    Application_Type: appInsightsType
    WorkspaceResourceId: workspaceId
  }
}
