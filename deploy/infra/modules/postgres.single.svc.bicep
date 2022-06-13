// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

@description('Server Name for Azure database for PostgreSQL')
param serverName string

@description('Database administrator login name')
@minLength(5)
param administratorLogin string

@description('Database administrator password')
@minLength(8)
@secure()
param administratorLoginPassword string

@description('Azure database for PostgreSQL compute capacity in vCores (2,4,8,16,32)')
param skuCapacity int = 2

@description('Azure database for PostgreSQL sku name ')
param skuName string = 'GP_Gen5_2'

@description('Azure database for PostgreSQL Sku Size ')
param skuSizeMB string = '51200'

@description('Azure database for PostgreSQL pricing tier')
@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
param skuTier string = 'GeneralPurpose'

@description('Azure database for PostgreSQL sku family')
param skuFamily string = 'Gen5'

@description('PostgreSQL version')
@allowed([
  '9.5'
  '9.6'
  '10'
  '10.0'
  '10.2'
  '11'
])
param postgresqlVersion string = '11'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('PostgreSQL Server backup retention days')
param backupRetentionDays int = 7

@description('Geo-Redundant Backup setting')
param geoRedundantBackup string = 'Disabled'

resource postgresql_server_resource 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: skuTier
    capacity: skuCapacity
    size: skuSizeMB
    family: skuFamily
  }
  properties: {
    createMode: 'Default'
    version: postgresqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    publicNetworkAccess: 'Enabled'
    storageProfile: {
      storageMB: skuSizeMB
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
  }
}

output pgServerName string = '${serverName}.postgres.database.azure.com'
output pgUserName string = '${administratorLogin}@${serverName}'
