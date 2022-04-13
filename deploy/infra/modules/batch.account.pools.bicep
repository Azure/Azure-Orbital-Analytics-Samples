// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param batchAccountName string
param batchAccountPoolName string
param batchPoolExists bool = false
param vmSize string

// Pool configuration
param imageReferencePublisher string = 'microsoft-azure-batch'
param imageReferenceOffer string
param imageReferenceSku string
param imageReferenceVersion string
param containerImageNames array = []
param containerRegistryPassword string = ''
param containerRegistryServer string = ''
param containerRegistryUsername string = ''
param nodeAgentSkuId string = 'batch.node.ubuntu 20.04'
param nodePlacementConfigurationPolicy string = ''
param batchAccountPoolDisplayName string = batchAccountPoolName
param interNodeCommunication bool = false

// Mount options
param azureFileShareConfigurationAccountKey string = ''
param azureFileShareConfigurationAccountName string = ''
param azureFileShareConfigurationAzureFileUrl string = ''
param azureFileShareConfigurationMountOptions string = ''
param azureFileShareConfigurationRelativeMountPath string = ''
param publicIPAddressConfigurationProvision string = ''

param fixedScaleResizeTimeout string = 'PT15M'
param fixedScaleTargetDedicatedNodes int = 1
param fixedScaleTargetLowPriorityNodes int = 0
param startTaskCommandLine string = ''
param startTaskEnvironmentSettings array = []
param startTaskMaxTaskRetryCount int = 0
param startTaskAutoUserElevationLevel string = 'Admin'
param startTaskautoUserScope string = 'Pool'
param startTaskWaitForSuccess bool = true
param taskSchedulingPolicy string = 'Pack'
param taskSlotsPerNode int = 1 

resource batchAccount 'Microsoft.Batch/batchAccounts@2021-06-01' existing = {
  name: batchAccountName
} 

resource batchAccountPool 'Microsoft.Batch/batchAccounts/pools@2021-06-01' = if (!batchPoolExists) {
  name: batchAccountPoolName
  parent: batchAccount
  properties: {
    vmSize: vmSize
    deploymentConfiguration: {    
      virtualMachineConfiguration: {
        imageReference: {
          offer: imageReferenceOffer
          publisher: imageReferencePublisher
          sku: imageReferenceSku
          version: imageReferenceVersion
        }
        containerConfiguration: {
          containerImageNames: containerImageNames
          containerRegistries: (empty(containerRegistryServer))? null: [
            {
              password: containerRegistryPassword
              registryServer: containerRegistryServer
              username: containerRegistryUsername
            }
          ]
          type: 'DockerCompatible'
        }
        nodeAgentSkuId: nodeAgentSkuId
        nodePlacementConfiguration: (empty(nodePlacementConfigurationPolicy))? {} : {
          policy: nodePlacementConfigurationPolicy
        }
      }
    }
    displayName: batchAccountPoolDisplayName
    interNodeCommunication: (interNodeCommunication) ? 'Enabled' : 'Disabled'

   
    mountConfiguration: (empty(azureFileShareConfigurationAccountName))? []: [
      {
        azureFileShareConfiguration: {
          accountKey: azureFileShareConfigurationAccountKey
          accountName: azureFileShareConfigurationAccountName
          azureFileUrl: azureFileShareConfigurationAzureFileUrl
          mountOptions: azureFileShareConfigurationMountOptions
          relativeMountPath: azureFileShareConfigurationRelativeMountPath
        }
      }
    ]
    networkConfiguration: (empty(publicIPAddressConfigurationProvision))? {}: {
      publicIPAddressConfiguration: {
        provision: publicIPAddressConfigurationProvision
      }
    }
    scaleSettings: {
      fixedScale: {
        resizeTimeout: fixedScaleResizeTimeout
        targetDedicatedNodes: fixedScaleTargetDedicatedNodes
        targetLowPriorityNodes: fixedScaleTargetLowPriorityNodes
      }
    }
    startTask: (empty(startTaskCommandLine))? {}: {
      commandLine: startTaskCommandLine
      environmentSettings: startTaskEnvironmentSettings
      userIdentity: {
        autoUser: {
          elevationLevel: startTaskAutoUserElevationLevel
          scope: startTaskautoUserScope
        }
      }
      maxTaskRetryCount: startTaskMaxTaskRetryCount
      waitForSuccess: startTaskWaitForSuccess
    }
    taskSchedulingPolicy: {
      nodeFillType: taskSchedulingPolicy
    }
    taskSlotsPerNode: taskSlotsPerNode
  }
}
