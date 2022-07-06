// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param name string
param kind string
param reserved bool
param maximumElasticWorkerCount int
param skuTier string
param skuSize string
param skuName string
param location string = resourceGroup().location
param environmentName string

resource hostingPlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: name
  location: location 
  kind: kind
  properties: {
    maximumElasticWorkerCount: maximumElasticWorkerCount
    reserved: reserved 
  }
  sku: {
    name: skuName 
    tier: skuTier
    size: skuSize
  }
  tags: {
    environment: environmentName
  }
}

output id string = hostingPlan.id 
