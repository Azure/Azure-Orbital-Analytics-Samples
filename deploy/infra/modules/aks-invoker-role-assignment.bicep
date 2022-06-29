// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param principalId string
param aksClusterName string
param customRoleDefId string
param roleAssignmentId string = guid(principalId, aksClusterName, customRoleDefId)

resource aks 'Microsoft.ContainerService/managedClusters@2021-10-01' existing = {
  name: aksClusterName
}

resource aksInvokerRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: roleAssignmentId
  scope: aks
  properties: {
    principalId: principalId
    roleDefinitionId: customRoleDefId
  }
}

output Id string = aksInvokerRoleAssignment.id



