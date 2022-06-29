// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param functionAppName string
param functionName string
param functionFiles object = {}
param functionLanguage string
param functionInputBinding object = {
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
  name: '${functionAppName}/${functionName}'
  properties: {
    config: {
      disabled: false
      bindings: [
        functionInputBinding
        functionOutputBinding
      ]
    }
    files: functionFiles
    language: functionLanguage
  }
}

output id string = function.id
#disable-next-line outputs-should-not-contain-secrets // we do not output to terminal. calling bicep will take this & store in keyvault
output functionkey string = listKeys(function.id, '2021-03-01').default
