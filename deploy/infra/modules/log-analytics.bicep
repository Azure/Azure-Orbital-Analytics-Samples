// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentName string
param workspaceName string
param location string
param sku string = 'pergb2018'

resource workspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: workspaceName
  location: location
  tags: {
    environment: environmentName    
  }
  properties: {
    sku: {
      name: sku
    }
  }
}

output workspaceId string = workspace.id
