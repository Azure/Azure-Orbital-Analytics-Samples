// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param privateDnsZoneName string
param customVnetId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: privateDnsZoneName
  location: 'global'
  properties : {
    registrationEnabled: false
    virtualNetwork: {
      id: customVnetId
    }
  }
}

