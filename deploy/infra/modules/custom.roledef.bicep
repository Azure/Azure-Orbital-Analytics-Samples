// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

@description('Array of actions for the roleDefinition')
param actions array = []

@description('Array of notActions for the roleDefinition')
param notActions array = []

@description('Friendly name of the role definition')
param roleName string

@description('Detailed description of the role definition')
param roleDescription string

var roleDefName_var = guid(roleName)

resource roleDefName 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: roleDefName_var
  properties: {
    roleName: roleName
    description: roleDescription
    type: 'customRole'
    permissions: [
      {
        actions: actions
        notActions: notActions
      }
    ]
    assignableScopes: [
      resourceGroup().id
    ]
  }
}

output Id string = roleDefName.id
