@description('Name for the container group')
param name string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Container image to deploy. Should be of the form repoName/imagename:tag for images stored in public Docker Hub, or a fully qualified URI for other registries. Images from private registries require additional registry credentials.')
param image string = 'mcr.microsoft.com/oss/mirror/docker.io/library/postgres:12.9-bullseye'

@description('Port to open on the container and the public IP address.')
param port int = 80

@description('The number of CPU cores to allocate to the container.')
param cpuCores int = 1

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb int = 2

param userManagedIdentityId string

param userManagedIdentityPrincipalId string

param assignRoleToUserManagedIdentity string = 'Owner'

@description('The behavior of Azure runtime if container has stopped.')
@allowed([
  'Always'
  'Never'
  'OnFailure'
])
param restartPolicy string = 'Never'

param server string

param db string = 'postgres'

param username string 

@secure()
param dbPassword string

param dbPort int = 5432

var commandString = 'apt update -y && apt install curl -y && curl -o root.crt https://cacerts.digicert.com/BaltimoreCyberTrustRoot.crt.pem && curl -o CVModelSQLScript.sql https://raw.githubusercontent.com/Azure/Azure-Orbital-Analytics-Samples/main/deploy/CVModelSQLScript.sql && psql --set=sslmode=require --set=sslrootcert=root.crt -h ${server} -p ${dbPort} -U ${username} -W -d ${db} -f CVModelSQLScript.sql'

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userManagedIdentityId}': {}
    }
  }
  properties: {
    containers: [
      {
        name: name
        properties: {
          command: [
            '/bin/bash' 
            '-c' 
            '${commandString}'
          ]
          environmentVariables: [
            {
              name: 'PGPASSWORD'
              secureValue: dbPassword
            }
          ]
          image: image
          ports: [
            {
              port: port
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: restartPolicy
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: port
          protocol: 'TCP'
        }
      ]
    }
  }
}

var role = {
  owner: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  contributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  reader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

resource umiRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid( userManagedIdentityId, role[toLower(assignRoleToUserManagedIdentity)] )
  scope: containerGroup
  properties: {
    principalId: userManagedIdentityPrincipalId
    roleDefinitionId: role[toLower(assignRoleToUserManagedIdentity)]
  }
}
