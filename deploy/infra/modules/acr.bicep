// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentName string
param location string = resourceGroup().location 
param acrName string 
param acrSku string = 'Standard'
param adminUserEnabled bool = true
param publicNetworkAccess bool = true
param zoneRedundancy bool = false
resource containerRepoitory 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: acrName
  location: location
  tags: {
    environment: environmentName    
  }
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: (publicNetworkAccess) ? 'Enabled' : 'Disabled'
    zoneRedundancy: (zoneRedundancy) ? 'Enabled' : 'Disabled'
  }
}
