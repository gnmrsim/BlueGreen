targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('The tags to be assigned to the created resources.')
param tags object = {}

@description('The name of the container apps environment.')
param containerAppsEnvironmentName string

@description('The name of the service')
param bgServiceName string

@description('The target port for the service.')
param bgPortNumber int

@description('The name of the container registry.')
param containerRegistryName string

@description('blue commit id')
param blueCommitId string

// ------------------
// VARIABLES
// ------------------

var containerRegistryPullRoleGuid='7f951dda-4ed3-4680-a7ca-43fe172d538d'

// ------------------
// RESOURCES
// ------------------

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppsEnvironmentName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-08-01-preview' existing = {
  name: containerRegistryName
}

resource containerUserAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'aca-user-identity-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
}

resource containerRegistryPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(!empty(containerRegistryName)) {
  name: guid(subscription().id, containerRegistry.id, containerUserAssignedManagedIdentity.id) 
  scope: containerRegistry
  properties: {
    principalId: containerUserAssignedManagedIdentity.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', containerRegistryPullRoleGuid)
    principalType: 'ServicePrincipal'
  }
}

module bgService 'container-apps/bg-service.bicep' = {
  name: 'bg-service-${uniqueString(resourceGroup().id)}'
  params: {
    bgServiceName: bgServiceName
    bgPortNumber: bgPortNumber
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.id
    containerRegistryName: containerRegistry.name
    containerUserAssignedManagedIdentityId: containerUserAssignedManagedIdentity.id
    blueCommitId: blueCommitId
  }
}
