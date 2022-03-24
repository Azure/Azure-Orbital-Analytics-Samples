// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentName string
param acrName string
param keyVaultName string
param containerRegistryLoginServerSecretName string = 'RegistryServer'
param containerRegistryUsernameSecretName string = 'RegistryUserName'
param containerRegistryPasswordSecretName string = 'RegistryPassword'
param utcValue string = utcNow()

resource containerRepository 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: acrName
} 

module acrLoginServerNameSecret './akv.secrets.bicep' = {
  name: 'acr-login-server-name-${utcValue}'
  params: {
    environmentName: environmentName
    keyVaultName: keyVaultName
    secretName: containerRegistryLoginServerSecretName
    secretValue: containerRepository.properties.loginServer
  }
}

module acrUsernameSecret './akv.secrets.bicep' = {
  name: 'acr-username-${utcValue}'
  params: {
    environmentName: environmentName
    keyVaultName: keyVaultName
    secretName: containerRegistryUsernameSecretName
    secretValue: containerRepository.listCredentials().username
  }
}

module acrPasswordSecret './akv.secrets.bicep' = {
  name: 'acr-password-${utcValue}'
  params: {
    environmentName: environmentName
    keyVaultName: keyVaultName
    secretName: containerRegistryPasswordSecretName
    secretValue: containerRepository.listCredentials().passwords[0].value
  }
}
