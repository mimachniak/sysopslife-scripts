targetScope = 'resourceGroup'

/*


$exampleRG = 'demo-dsc-bicep-rg'
$adminUserName = 'godmode'
$location = 'West Europe'

New-AzResourceGroup -Name $exampleRG -Location $location

New-AzResourceGroupDeployment -ResourceGroupName $exampleRG -TemplateFile ./main.bicep -adminUserName $adminUserName -verbose

*/

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')

@description('Name for the Public IP used to access the Virtual Machine.')
param publicIpName string = 'myPublicIP'

@description('Allocation method for the Public IP used to access the Virtual Machine.')
param publicIPAllocationMethod string = 'Static'

@description('SKU for the Public IP used to access the Virtual Machine.')
param publicIpSku string = 'Standard'

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
@allowed([
  '2016-datacenter-gensecond'
  '2016-datacenter-server-core-g2'
  '2016-datacenter-server-core-smalldisk-g2'
  '2016-datacenter-smalldisk-g2'
  '2016-datacenter-with-containers-g2'
  '2016-datacenter-zhcn-g2'
  '2019-datacenter-core-g2'
  '2019-datacenter-core-smalldisk-g2'
  '2019-datacenter-core-with-containers-g2'
  '2019-datacenter-core-with-containers-smalldisk-g2'
  '2019-datacenter-gensecond'
  '2019-datacenter-smalldisk-g2'
  '2019-datacenter-with-containers-g2'
  '2019-datacenter-with-containers-smalldisk-g2'
  '2019-datacenter-zhcn-g2'
  '2022-datacenter-azure-edition'
  '2022-datacenter-azure-edition-core'
  '2022-datacenter-azure-edition-core-smalldisk'
  '2022-datacenter-azure-edition-smalldisk'
  '2022-datacenter-core-g2'
  '2022-datacenter-core-smalldisk-g2'
  '2022-datacenter-g2'
  '2022-datacenter-smalldisk-g2'
  '2025-datacenter-azure-edition'
  '2025-datacenter-azure-edition-core'
  '2025-datacenter-azure-edition-core-smalldisk'
  '2025-datacenter-azure-edition-smalldisk'
  '2025-datacenter-core'
  '2025-datacenter-core-g2'
  '2025-datacenter-core-smalldisk'
  '2025-datacenter-core-smalldisk-g2'
  '2025-datacenter-g2'
  '2025-datacenter-smalldisk'
  '2025-datacenter-smalldisk-g2'
])
param OSVersion string = '2025-datacenter-azure-edition'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2s_v5'

@description('Location for all resources.')
param location string = 'West Europe'

@description('Name of the virtual machine.')
param vmName string = 'd-vm-w-dsc01'

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'Standard'


var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var nicName = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = 'MyVNET'
var networkSecurityGroupName = 'default-NSG'
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
var extensionName = 'GuestAttestation'
var extensionPublisher = 'Microsoft.Azure.Security.WindowsAttestation'
var extensionVersion = '1.0'
var maaTenantName = 'GuestAttestation'
var maaEndpoint = substring('emptyString', 0, 0)


resource storageAccount 'Microsoft.Storage/storageAccounts@2026-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}


resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [

    virtualNetwork
  ]
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
        // storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}

resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
  parent: vm
  name: extensionName
  location: location
  properties: {
    publisher: extensionPublisher
    type: extensionName
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: maaEndpoint
          maaTenantName: maaTenantName
        }
      }
    }
  }
}

output hostname string = publicIp.properties.dnsSettings.fqdn

resource runCommandsInstallDSC 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'DSC-Install'
  location: location
  properties: {
    timeoutInSeconds: 900
    treatFailureAsDeploymentFailure: true
    parameters: [
      {
        name: 'dscVersion'
        value: '3.2.0'
      }
      {
        name: 'dscArch'
        value: 'x86_64-pc-windows-msvc'
      }

    ]
    source: {
      script: '''
          #Requires -RunAsAdministrator

          param(
              [string]$dscVersion,
              [string]$dscArch
          )
          $downloadUrl = "https://github.com/PowerShell/DSC/releases/download/v$dscVersion/DSC-$dscVersion-$dscArch.zip"
          $installDir  = "C:\Program Files\DSC\$dscVersion"
          $zipPath     = Join-Path $env:TEMP "DSC-$dscVersion-$dscArch.zip"
          $logPath     = Join-Path $env:TEMP "DSC-$dscVersion-install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

          $ProgressPreference = 'SilentlyContinue'

          function Write-Log {
              param([string]$Message, [ValidateSet('INFO','WARN','ERROR')]$Level = 'INFO')
              $entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
              Write-Host $entry
              Add-Content -Path $logPath -Value $entry
          }

          Write-Log "Log file: $logPath"
          Write-Log "Install directory: $installDir"
          Write-Log "Download URL: $downloadUrl"

          # Download
          Write-Log "Downloading DSC v$dscVersion..."
          try {
              Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
              Write-Log "Download completed: $zipPath"
          } catch {
              Write-Log "Download failed: $_" -Level ERROR
              exit 1
          }

          # Extract
          if (-not (Test-Path $installDir)) {
              New-Item -ItemType Directory -Path $installDir -Force | Out-Null
              Write-Log "Created directory: $installDir"
          }
          Write-Log "Extracting to $installDir..."
          try {
              Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
              Write-Log "Extraction completed."
          } catch {
              Write-Log "Extraction failed: $_" -Level ERROR
              exit 1
          }

          # Add to system PATH if not already present
          $currentPath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
          if ($currentPath -split ';' -notcontains $installDir) {
              Write-Log "Adding $installDir to system PATH..."
              [Environment]::SetEnvironmentVariable('Path', "$currentPath;$installDir", 'Machine')
              Write-Log "System PATH updated. Restart your shell to apply changes."
          } else {
              Write-Log "$installDir is already in the system PATH." -Level WARN
          }

          # Cleanup temp file
          Remove-Item -Path $zipPath -Force
          Write-Log "Removed temporary file: $zipPath"

          Write-Log "DSC v$dscVersion installed successfully."
          Write-Log "Full log saved to: $logPath"

      '''

    }
  }
}


resource runCommandsApplyDSC 'Microsoft.Compute/virtualMachines/runCommands@2025-11-01' = {
  parent: vm
  name: 'DSC-Configuration'
  location: location
  properties: {
    timeoutInSeconds: 900
    treatFailureAsDeploymentFailure: true
    parameters: [
      {
        name: 'dscInstallDir'
        value: '3.2.0'
      }
    ]
    source: {
      script: '''

        param(
          [string]$dscInstallDir
        )

        $dscInstallDir = "C:\Program Files\DSC\$dscInstallDir"
        Write-Host "DSC for certificate "

        # Add DSC install dir to current user PATH if not already present
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($userPath -split ';' -notcontains $dscInstallDir) {
            [Environment]::SetEnvironmentVariable('Path', "$userPath;$dscInstallDir", 'User')
            Write-Host "Added $dscInstallDir to user PATH."
        }
        # Also update the current session so dsc.exe is resolvable immediately
        if ($env:PATH -split ';' -notcontains $dscInstallDir) {
            $env:PATH = "$env:PATH;$dscInstallDir"
        }


        $contentYamlCert = Invoke-RestMethod -Uri "https://bootdiagsvbrct4aptey7o.blob.core.windows.net/dsc/ps-script-certificate.dsc.yaml"
        $result = $contentYamlCert | dsc config set --file - --output-format pretty-json
        $result = $result | ConvertFrom-Json

        $thumbprint = if ($result.results.result.afterState.output -is [System.Array]) {
            $result.results.result.afterState.output[0].Thumbprint
        } else {
            $result.results.result.afterState.output.Thumbprint
        }

        if (-not $thumbprint) {
            throw "Thumbprint was not found in DSC output."
        }


        Write-Host "DSC for certificate Thumbprint: " $thumbprint

        $inlineParams = @{
            parameters = @{
                certThumbprint = $thumbprint
            }
        } | ConvertTo-Json

        # dsc config --parameters $inlineParams get --file .\winrm.dsc.yaml
        # dsc config --parameters $inlineParams test --file .\winrm.dsc.yaml

        Write-Host "DSC - winrm HTTPS setup"

        $contentYamlWinrm = Invoke-RestMethod -Uri "https://bootdiagsvbrct4aptey7o.blob.core.windows.net/dsc/winrm.dsc.yaml"

        $contentYamlWinrm | dsc config --parameters $inlineParams set --file -


      '''

    }
  }
  dependsOn: [
    runCommandsInstallDSC
  ]
}
