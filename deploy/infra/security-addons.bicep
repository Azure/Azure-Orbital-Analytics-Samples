targetScope='subscription'

param environmentCode string
param location string
param synapseSuffix string = 'azuresynapse.net'
var pipelineRgName = '${environmentCode}-pipeline-rg'
var networkRgName = '${environmentCode}-network-rg'

resource customVnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: '${environmentCode}-vnet'
  scope: resourceGroup(networkRgName)
}
resource pipelineSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' existing = {
  name: '${environmentCode}-vnet/pipeline-subnet'
  scope: resourceGroup(networkRgName)
}

resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' existing = {
  name: '${environmentCode}-pipeline-syn-ws'
  scope: resourceGroup(pipelineRgName)
}

module addSynapaseDevPrivateLink 'modules/privatelink.bicep' = {
  name: '${environmentCode}-synpasews-dev-plink'
  scope: resourceGroup(networkRgName)
  params: {
    customVnetId: customVnet.id
    privateDnsZoneName: 'privatelink.dev.${synapseSuffix}'
  }
}
module addSynapseSqlPrivateLink 'modules/privatelink.bicep' = {
  name: '${environmentCode}-sql-plink'
  scope: resourceGroup(networkRgName)
  params: {
    customVnetId: customVnet.id
    privateDnsZoneName: 'privatelink.sql.${synapseSuffix}'
  }
}

module addSynapseDevPrivateEndpoint 'modules/privateendpoints.bicep' = {
  name: '${environmentCode}-synpasews-dev-pe'
  scope: resourceGroup(networkRgName)
  params: {
    environmentCode: environmentCode
    location:location
    subnetId: pipelineSubnet.id
    privateLinkServiceId: synapseWorkspace.id
    privateDnsZoneName: 'privatelink.dev.${synapseSuffix}'
    groupIds: [ 
      'Dev'
    ]
  }
  dependsOn: [
    addSynapaseDevPrivateLink
  ]
}

module addSynapseSqlPrivateEndpoint 'modules/privateendpoints.bicep' = {
  name: '${environmentCode}-synpasews-sql-pe'
  scope: resourceGroup(networkRgName)
  params: {
    environmentCode: environmentCode
    location:location
    subnetId: pipelineSubnet.id
    privateLinkServiceId: synapseWorkspace.id
    privateDnsZoneName: 'privatelink.sql.${synapseSuffix}'
    groupIds: [ 
      'Sql'
    ]
  }
  dependsOn: [
    addSynapseSqlPrivateLink
  ]
}

module addSynapseSqlOnDemandPrivateEndpoint 'modules/privateendpoints.bicep' = {
  name: '${environmentCode}-synpasews-sql-ondemand-pe'
  scope: resourceGroup(networkRgName)
  params: {
    environmentCode: environmentCode
    location:location
    subnetId: pipelineSubnet.id
    privateLinkServiceId: synapseWorkspace.id
    privateDnsZoneName: 'privatelink.sql.${synapseSuffix}'
    groupIds: [ 
      'SqlOnDemand'
    ]
  }
  dependsOn: [
    addSynapseSqlPrivateLink
  ]
}

output customVnetId string = customVnet.id
output customVnetName string = customVnet.name
output pipelineSubnetId string = pipelineSubnet.id
output pipelineSubnetName string = pipelineSubnet.name
output synapseWorkspaceProperties object = synapseWorkspace.properties








