// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param appName string
param name string
param files object = {}
param language string
param inputBinding object = {
  name: 'req'
  type: 'httpTrigger'
  direction: 'in'
  authLevel: 'function'
  methods: [
    'post'
  ]  
}
param functionOutputBinding object = {
  name: '$return'
  type: 'http'
  direction: 'out'
}

resource function 'Microsoft.Web/sites/functions@2021-03-01' = {
  name: '${appName}/${name}'
  properties: {
    config: {
      disabled: false
      bindings: [
        inputBinding
        functionOutputBinding
      ]
    }
    files: files
    language: language
  }
}

output id string = function.id
output fullName string = function.name
