@description('Name for the container group')
param par_name string = 'acilinuxpublicipcontainergroup'


@description('Container image to deploy. Should be of the form repoName/imagename:tag for images stored in public Docker Hub, or a fully qualified URI for other registries. Images from private registries require additional registry credentials.')
param par_image string = 'mcr.microsoft.com/azuredocs/aci-helloworld'

@description('Port to open on the container and the public IP address.')
param par_port int = 80

@description('The number of CPU cores to allocate to the container.')
param par_cpu_cores int = 1

@description('The amount of memory to allocate to the container in gigabytes.')
param par_memory_in_gb int = 2

@description('The behavior of Azure runtime if container has stopped.')
@allowed([
  'Always'
  'Never'
  'OnFailure'
])
param par_restart_policy string = 'Always'

param par_environment_variables array = []
param par_volume_mounts array = []
param par_volumes array = []
param par_image_registry_credentials array = []
param par_tags object

resource res_aci 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = {
  name: par_name
  location: resourceGroup().location
  tags: par_tags
  properties: {
    containers: [
      {
        name: par_name
        properties: {
          image: par_image
          ports: [
            {
              port: par_port
              protocol: 'TCP'
            }
          ]
          environmentVariables: par_environment_variables
          volumeMounts: par_volume_mounts
          resources: {
            requests: {
              cpu: par_cpu_cores
              memoryInGB: par_memory_in_gb
            }
          }
        }
      }
    ]
    imageRegistryCredentials: par_image_registry_credentials
    osType: 'Linux'
    restartPolicy: par_restart_policy
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: par_port
          protocol: 'TCP'
        }
      ]
    }
    volumes: par_volumes
  }
}

output containerIPv4Address string = res_aci.properties.ipAddress.ip
