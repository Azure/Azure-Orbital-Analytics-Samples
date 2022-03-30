// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

targetScope='subscription'

param environmentName string
param resourceGroupName string
param resourceGroupLocation string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: resourceGroupLocation 
  tags: {
    environment: environmentName
  }
}

output rgLocation string = rg.location
output rgId string = rg.id
