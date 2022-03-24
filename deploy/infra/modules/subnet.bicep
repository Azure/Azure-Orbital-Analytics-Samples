// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param vNetName string
param subnetName string
param subnetAddressPrefix string
param serviceEndPoints array = []


//Subnet with RT and NSG
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  name: '${vNetName}/${subnetName}'
  properties: {
    addressPrefix: subnetAddressPrefix
    serviceEndpoints: serviceEndPoints
  }
}
