// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param batchAccountName string
param batchPoolName string 
param userManagedIdentityName string
param userManagedIdentityResourcegroupName string
param location string = resourceGroup().location
param utcValue string = utcNow()

resource queryuserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  scope: resourceGroup(userManagedIdentityResourcegroupName)
  name: userManagedIdentityName
}

resource runPowerShellInlineWithOutput 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'runPowerShellInlineWithOutput${utcValue}'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${queryuserManagedIdentity.id}': {}
    }
  }
  properties: {
    forceUpdateTag: utcValue
    azPowerShellVersion: '6.4'
    scriptContent: '''
      param([string] $batchAccountName, [string] $batchPoolName)
      Write-Output $output
      $DeploymentScriptOutputs = @{}
      $batchContext = Get-AzBatchAccount -AccountName $batchAccountName
      $DeploymentScriptOutputs = Get-AzBatchPool -Id $batchPoolName -BatchContext $batchContext 
    '''
    arguments: '-batchAccountName ${batchAccountName} -batchPoolName ${batchPoolName}'
    timeout: 'PT1H'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

output batchPoolExists bool = contains(runPowerShellInlineWithOutput.properties, 'outputs')
