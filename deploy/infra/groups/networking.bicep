// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// List of required parameters
param environmentCode string
param projectName string
param Location string

// Parameters with default values for Virtual Network
param virtualNetworkName string = ''
param vnetAddressPrefix string = '10.5.0.0/16'
param pipelineSubnetAddressPrefix string = '10.5.1.0/24'
param dataSubnetAddressPrefix string = '10.5.2.0/24'
param orchestrationSubnetAddressPrefix string = '10.5.3.0/24'

var namingPrefix = '${environmentCode}-${projectName}'

module vnet '../modules/vnet.bicep' = {
  name: virtualNetworkName
  params: {
    virtualNetworkName: virtualNetworkName
    location: Location
    addressPrefix: vnetAddressPrefix
  }
}

module pipelineSubnet '../modules/subnet.bicep' = {
  name: '${namingPrefix}-pipeline-subnet'
  params: {
    vNetName: virtualNetworkName
    subnetName: 'pipeline-subnet'
    subnetAddressPrefix: pipelineSubnetAddressPrefix
  }
  dependsOn: [
    vnet
  ]
}

module dataSubnet '../modules/subnet.bicep' = {
  name: '${namingPrefix}-data-subnet'
  params: {
    vNetName: virtualNetworkName
    subnetName: 'data-subnet'
    subnetAddressPrefix: dataSubnetAddressPrefix
  }
  dependsOn: [
    pipelineSubnet
  ]
}

module orchestrationSubnet '../modules/subnet.bicep' = {
  name: '${namingPrefix}-orchestration-subnet'
  params: {
    vNetName: virtualNetworkName
    subnetName: 'orchestration-subnet'
    subnetAddressPrefix: orchestrationSubnetAddressPrefix
  }
  dependsOn: [
    dataSubnet
  ]
}
