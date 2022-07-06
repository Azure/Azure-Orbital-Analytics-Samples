// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param kubeletIdentityId string
param acrName string
param roleAssignmentId string = guid(kubeletIdentityId, kubeletIdentityId, acrName)
//this RoleId maps to AcrPull role
var acrPullRoleId = '/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource acr 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: acrName
}

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: roleAssignmentId
  scope: acr
  properties: {
    principalId: kubeletIdentityId
    roleDefinitionId: acrPullRoleId
  }
}
