param aspName string
param aspKind string
param aspReserved bool
param mewCount int
param skuTier string
param skuSize string
param skuName string
param location string = resourceGroup().location
param environmentName string

resource hostingPlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: aspName
  location: location 
  kind: aspKind
  properties: {
    maximumElasticWorkerCount: mewCount
    reserved: aspReserved 
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

 