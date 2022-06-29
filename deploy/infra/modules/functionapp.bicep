// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param functionAppName string
param functionName string
param serverFarmId string
param location string = resourceGroup().location
param appInsightsInstrumentationKey string 
param storageAccountName string
param storageAccountKey string
param functionRuntime string
param environmentName string
param extendedSiteConfig object = {}
param extendedAppSettings object = {}

var defaultAppSetting = {
  AzureWebJobsStorage                      : 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountKey}'
  WEBSITE_CONTENTSHARE                     : toLower('${functionName}-content')
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING : 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountKey}'
  APPINSIGHTS_INSTRUMENTATIONKEY           : appInsightsInstrumentationKey
  APPLICATIONINSIGHTS_CONNECTION_STRING    : 'InstrumentationKey=${appInsightsInstrumentationKey}'
  FUNCTIONS_WORKER_RUNTIME                 : functionRuntime
  FUNCTIONS_EXTENSION_VERSION              : '~4'
}

var defaultSiteConfig = {
  cors: {
    allowedOrigins: [
      'https://portal.azure.com'
    ]
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  tags : {
    type: 'functionapp'
    environment: environmentName
  }
  kind: 'functionapp'
  properties: {
    serverFarmId: serverFarmId
    siteConfig: union(defaultSiteConfig, extendedSiteConfig)
    httpsOnly: true
  }
}

resource functionAppSettings 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'appsettings'
  parent: functionApp
  properties: union(defaultAppSetting, extendedAppSettings)
}
output id string = functionApp.id
