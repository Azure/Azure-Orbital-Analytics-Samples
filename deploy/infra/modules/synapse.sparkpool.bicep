// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentName string 
param location string = resourceGroup().location
param synapseWorkspaceName string
param sparkPoolName string
param autoPauseEnabled bool = true
param autoPauseDelayInMinutes int = 15
param autoScaleEnabled bool = true
param autoScaleMinNodeCount int = 1
param autoScaleMaxNodeCount int = 5
param cacheSize int = 0 
param dynamicExecutorAllocationEnabled bool = false
param isComputeIsolationEnabled bool = false
param nodeCount int = 0
param nodeSize string
param nodeSizeFamily string
param sparkVersion string = '3.1'
param poolId string = 'default'


resource synapseWorspace 'Microsoft.Synapse/workspaces@2021-06-01' existing = {
  name: synapseWorkspaceName
}
 
resource synapseSparkPool 'Microsoft.Synapse/workspaces/bigDataPools@2021-06-01' = {
  name: sparkPoolName
  location: location
  tags: {
    environment: environmentName    
    poolId: poolId
  }
  parent: synapseWorspace
  properties: {
    autoPause: {
      delayInMinutes: autoPauseDelayInMinutes
      enabled: autoPauseEnabled
    }
    autoScale: {
      enabled: autoScaleEnabled
      maxNodeCount: autoScaleMaxNodeCount
      minNodeCount: autoScaleMinNodeCount
    }
    cacheSize: cacheSize
    dynamicExecutorAllocation: {
      enabled: dynamicExecutorAllocationEnabled
    }
    isComputeIsolationEnabled: isComputeIsolationEnabled
    nodeCount: nodeCount
    nodeSize: nodeSize
    nodeSizeFamily: nodeSizeFamily
    sparkVersion: sparkVersion
  }
}
