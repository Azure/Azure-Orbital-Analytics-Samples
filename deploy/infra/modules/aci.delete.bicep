// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param location string = resourceGroup().location
param utcValue string = utcNow()
param aciName string
param uamiName string

resource dataUami 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: uamiName
}

resource deleteContainer 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deleteContainer${utcValue}'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${dataUami.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.9.1'
    forceUpdateTag: utcValue
    retentionInterval: 'P1D'
    scriptContent: 'az container delete -n ${aciName} -g ${resourceGroup().name} -y'
    timeout: 'PT30M'
    cleanupPreference: 'Always'
  }
}

output uamiId string = dataUami.id
