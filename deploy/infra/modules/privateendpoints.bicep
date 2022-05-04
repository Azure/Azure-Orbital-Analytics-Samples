// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param environmentCode string
param location string
param subnetId string
param privateLinkServiceId string
param privateDnsZoneName string
param groupIds array

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' existing = {
  parent: privateDnsZone
  name: privateDnsZoneName
}

resource privateEndpoints 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: guid(environmentCode, privateLinkServiceId, groupIds[0])
  location: location
  dependsOn: [
    privateDnsZoneLink
  ]
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: guid(environmentCode, privateLinkServiceId, groupIds[0])
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: privateEndpoints
  name: guid(environmentCode, privateLinkServiceId, groupIds[0])
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZone.name
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}
