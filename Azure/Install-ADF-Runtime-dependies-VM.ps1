<#  
.SYNOPSIS  
    Install all dependencies for Azure Data Factory Runtime.
.DESCRIPTION  
Script will download and install all required software for 
Azure Data Factory Runtime Integration on Virtual Machine.
 
    
.NOTES  
    File Name  : Install-ADF-Runtime-dependies-VM.ps1 
    Author     : Michal Machniak  
    Requires   : PowerShell V5.1
    Modules    : None
.LINK

    Github: https://github.com/mimachniak/sysopslife-scripts
    Site: https://sysopslife.sys4ops.pl/
#>


[CmdletBinding()]
param (

    [Parameter(Mandatory=$true,HelpMessage="Integration Runtime Key")]
    [String]$IntegrationRuntimeKey

)


$TempInstallRoot = 'C:\Temp'
$dmgcmd = "C:\Program Files\Microsoft Integration Runtime\5.0\Shared\dmgcmd.exe"

write-host "Creating temporary folder fo Installs packed" -ForegroundColor Green

    if ((Test-Path $TempInstallRoot\Install) -eq $false ){
        New-Item C:\Temp\Install -ItemType Directory -Force
    }

    Write-Host "Download dependies ... vcredist_x64.exe"

    ## Install C++ vcredist_x64.exe

    $url = "https://download.microsoft.com/download/3/2/2/3224B87F-CFA0-4E70-BDA3-3DE650EFEBA5/vcredist_x64.exe"
    $output = "$TempInstallRoot\Install\vcredist_x64.exe"
    $start_time = Get-Date

    Write-Host "Check that dependies is Downloaded [vcredist_x64.exe] "

    if (!(test-path -Path $output))

    {

        Write-Host "Downloading ... [vcredist_x64.exe] "

        Invoke-WebRequest -Uri $url -OutFile $output
        Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

        if (!(test-path -Path HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\10.0\VC\VCRedist\x64\))
        {

            Write-Host "Install: [vcredist_x64.exe] "

            Start-Process $output -ArgumentList "/install /quiet /norestart" -Wait -Passthru

        }
        else {

            Write-Host "[vcredist_x64.exe] is alredy installed"
        }

    }
    else {
    
        Write-Host " Files exist in [$TempInstallRoot] [vcredist_x64.exe] "


        if (!(test-path -Path HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\10.0\VC\VCRedist\x64\))
        {

            Write-Host "Installing: [vcredist_x64.exe]"

            Start-Process $output -ArgumentList "/install /quiet /norestart" -Wait -Passthru

        }
        else {

            Write-Host "[vcredist_x64.exe] is alredy installed"
        }
    
    }

    ## Install OpenJDK

    $url = "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.10%2B9_openj9-0.24.0/OpenJDK11U-jdk_x64_windows_openj9_11.0.10_9_openj9-0.24.0.msi"
    $output = "$TempInstallRoot\Install\OpenJDK11U-jdk_x64_windows_openj9_11.0.10_9_openj9-0.24.0.msi"
    $start_time = Get-Date

    Write-Host "Check that dependies is Downloaded [OpenJDK11U] "

    if (!(test-path -Path $output))

    {

        Write-Host "Downloading ... [OpenJDK11U] "

        Invoke-WebRequest -Uri $url -OutFile $output
        Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

        if (!(test-path -Path 'C:\Program Files\AdoptOpenJDK\'))
        {

            Write-Host "Installing: [OpenJDK11U]"

            Start-Process $output -Wait -ArgumentList 'ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome INSTALLDIR="C:\Program Files\AdoptOpenJDK\" /quiet'

        }
        else {
            
            Write-Host "[OpenJDK11U] is alredy installed"
        }
    }
    else {

        Write-Host " Files exist in [$TempInstallRoot] [OpenJDK11U] "

        if (!(test-path -Path 'C:\Program Files\AdoptOpenJDK\'))
        {

            Write-Host "Installing: [OpenJDK11U]"

            Start-Process $output -Wait -ArgumentList 'ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome INSTALLDIR="C:\Program Files\AdoptOpenJDK\" /quiet'

        }
        else {
            
            Write-Host "[OpenJDK11U] is alredy installed"
        }

    }
    ## Install Runtime

    $url = "https://download.microsoft.com/download/E/4/7/E4771905-1079-445B-8BF9-8A1A075D8A10/IntegrationRuntime_5.2.7740.4.msi"
    $output = "$TempInstallRoot\Install\IntegrationRuntime_5.2.7740.4.msi"
    $start_time = Get-Date

    if (!(test-path -Path $output))

    {
        ### Download files

        Write-Host "Check that dependies is Downloaded [IntegrationRuntime] "

        Invoke-WebRequest -Uri $url -OutFile $output

        Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"


        ### Install Gateway if(!(test-path -Path "C:\Program Files\Microsoft Integration Runtime"))

        if(!(test-path -Path "C:\Program Files\Microsoft Integration Runtime"))
        {

            Write-Host "ADF Runtime Need to be install"

            Write-Host "Start Gateway installation"

                Start-Process $output -Wait -ArgumentList '/quiet /passive'

            Start-Sleep -Seconds 30

            ## Register Gateway

                Start-Process -FilePath $dmgcmd -ArgumentList "-RegisterNewNode $IntegrationRuntimeKey $env:COMPUTERNAME" -NoNewWindow -PassThru -Wait

            Write-Host "Succeed to register gateway"
        }
        else
        {
            Write-Host "ADF Runtime installation found"

            ## Register Gateway

                Start-Process -FilePath $dmgcmd -ArgumentList "-RegisterNewNode $IntegrationRuntimeKey $env:COMPUTERNAME" -NoNewWindow -PassThru -Wait

            Write-Host "Succeed to register gateway"

        }
    }
    else
    {

        Write-Host " Files exist in [$TempInstallRoot] [IntegrationRuntime] "
        
        if(!(test-path -Path "C:\Program Files\Microsoft Integration Runtime"))
        {

            Write-Host "ADF Runtime Need to be install"

            Write-Output "Start Gateway installation"

                Start-Process $output -Wait -ArgumentList '/quiet /passive'

            Start-Sleep -Seconds 30

            ## Register Gateway

                Start-Process -FilePath $dmgcmd -ArgumentList "-RegisterNewNode $IntegrationRuntimeKey $env:COMPUTERNAME" -NoNewWindow -PassThru -Wait

            Write-Host "Succeed to register gateway"
        }
        else
        {

            Write-Host "ADF Runtime installation found"
            ## Register Gateway

                Start-Process -FilePath $dmgcmd -ArgumentList "-RegisterNewNode $IntegrationRuntimeKey $env:COMPUTERNAME" -NoNewWindow -PassThru -Wait

            Write-Host "Succeed to register gateway"

        }


    }