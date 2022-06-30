// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentName string
param location string = resourceGroup().location 
param clusterName string
param nodeCount int = 3
param vmSize string = 'Standard_D2s_v4'
param networkPlugin string = 'azure'
param networkMode string = 'transparent'
param logAnalyticsWorkspaceResourceID string

resource aks 'Microsoft.ContainerService/managedClusters@2022-01-01' = {
  name: clusterName
  location: location
  tags: {
    environment: environmentName
    type: 'k8s'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: clusterName
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'default'
        count: nodeCount
        vmSize: vmSize
        mode: 'System'
        nodeLabels: {
          App : 'default'
        }
      }
    ]
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceResourceID
        }
      }
    }
    networkProfile: {
      networkPlugin: networkPlugin
      networkMode: networkMode
    }
  }
}

output Id string = aks.id
output principalId string = aks.identity.principalId
output kubeletIdentityId string = aks.properties.identityProfile.kubeletidentity.objectId
