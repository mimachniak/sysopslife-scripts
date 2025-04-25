Install-Module cNtfsAccessControl -Confirm:$false -AllowClobber -Force
Install-Module WebAdministrationDsc -Confirm:$false -AllowClobber -Force 
Install-Module ComputerManagementDsc -Confirm:$false -AllowClobber -Force 



Configuration web_crl_publish {

    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path = "C:\PKI",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AdDomain = (Get-ComputerInfo).CsDomain
    )

Import-DscResource -Module PSDesiredStateConfiguration
Import-DscResource -Module cNtfsAccessControl
Import-DscResource -Module WebAdministrationDsc
Import-DscResource -Module ComputerManagementDsc



        # Folder exist

        File PkiFolder {
            Type = 'Directory'
            DestinationPath = $Path
            Ensure = "Present"
        }

        # Grant Modify permissions to a user

        SmbShare PkiShare
        {
            Ensure = "Present"
            Name   = "PKI"
            Path = $Path
            Description = "Shared PKI files"
            FullAccess   = @("$($AdDomain)\Cert Publishers")
            ReadAccess = @('Everyone')
            DependsOn = '[File]PkiFolder'
        }


        # Install web Server

        WindowsFeature IIS
        {
            Ensure                  = 'Present'
            Name                    = 'Web-Server'
            DependsOn               = '[File]PkiFolder'
        }

        WindowsFeature IIS_Managment_tools
        {
            Ensure                  = 'Present'
            Name                    = 'Web-Mgmt-Console'
            DependsOn               = '[WindowsFeature]IIS'
        }

        # Start the Default Web Site
        WebSite DefaultSite
        {
            Ensure                  = 'Present'
            Name                    = 'Default Web Site'
            State                   = 'Started'
            PhysicalPath            = $Path
            DependsOn               = '[WindowsFeature]IIS'
        }
        
        WebConfigProperty DefaultWebSite_directory_browsing
        {
            WebsitePath  = 'IIS:\Sites\Default Web Site'
            Filter       = 'system.webServer/directoryBrowse'
            PropertyName = 'enabled'
            Value        = 'true'
            Ensure       = 'Present'
        }

        WebConfigProperty DefaultWebSite_allowDoubleEscaping
        {
            WebsitePath  = 'IIS:\Sites\Default Web Site'
            Filter       = 'system.webServer/security/requestFiltering'
            PropertyName = 'allowDoubleEscaping'
            Value        = 'true'
            Ensure       = 'Present'
        }

        #Permission assigne 
        cNtfsPermissionEntry IIS_IUSRS_Permissions
        {
            Ensure = 'Present'
            Path = $Path
            Principal = 'BUILTIN\IIS_IUSRS'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
            DependsOn = '[WindowsFeature]IIS'
        }

        cNtfsPermissionEntry IIS_IUSR_Permissions
        {
            Ensure = 'Present'
            Path = $Path
            Principal = 'BUILTIN\IIS_IUSR'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
            DependsOn = '[WindowsFeature]IIS'
        }

        cNtfsPermissionEntry IIS_IUSRS_Cert_Publishers
        {
            Ensure = 'Present'
            Path = $Path
            Principal = "$($AdDomain)\Cert Publishers"
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
            DependsOn = '[WindowsFeature]IIS'
        }

        



}


web_crl_publish
<#
Start-DscConfiguration -Path .\web_crl_publish -verbose -Wait -Force

#>