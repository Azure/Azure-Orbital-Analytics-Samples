// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param location string = resourceGroup().location
param uamiName string
param environmentName string

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: uamiName
  location: location
  tags: {
    environment: environmentName    
  }
}

output uamiId string = uami.id
output uamiPrincipalId string = uami.properties.principalId
output uamiClientId string = uami.properties.clientId
output uamiTenantId string = uami.properties.tenantId
