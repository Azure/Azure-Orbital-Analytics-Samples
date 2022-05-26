// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

targetScope = 'subscription'

param roleName string
param roleDescription string = ''
param allowedActions array = []
param allowedDataActions array = []
param deniedActions array = []
param deniedDataActions array = []

resource customRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid(roleName)
  properties: {
    description: roleDescription
    assignableScopes: [
      subscription().id
    ]
    permissions: [
      {
        actions: allowedActions
        dataActions: allowedDataActions
        notActions: deniedActions
        notDataActions: deniedDataActions
      }
    ]
    roleName: roleName
    type: 'CustomRole'
  }
}

output customRoleID string = customRole.id
