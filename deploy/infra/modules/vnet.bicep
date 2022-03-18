// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// Name of the VNET.
param virtualNetworkName string
param location string = resourceGroup().location
param addressPrefix string


resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
    ]
  }
}
