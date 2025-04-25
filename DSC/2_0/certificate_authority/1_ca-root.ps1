

Install-Module -Name ActiveDirectoryCSDsc -Confirm:$false -Force -AllowClobber

#/Requires -module @{Modulename = 'ActiveDirectoryCSDsc'; ModuleVersion = '5.0.0.0'}

Configuration Root_CertificationAuthority_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        $Credential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        $CACommonName = 'Contoso Root CA',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [ValidateSet('1024','2048','4096')]
        $KeyLength = '4096',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        $CACertPublicationURLs = @(
            '1:C:\Windows\system32\CertSrv\CertEnroll\%1_%3%4.crt'
            '2:http://pki.contoso.com/CertEnroll/%1_%3%4.crt'
        ),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        $CRLPublicationURLs = @(
            '65:C:\Windows\system32\CertSrv\CertEnroll\%3%8%9.crl'
            '6:http://pki.contoso.com/CertEnroll/%3%8%9.crl'
        )
    )

    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module ActiveDirectoryCSDsc

    Node localhost
    {
        WindowsFeature ADCS-Cert-Authority
        {
            Ensure = 'Present'
            Name   = 'ADCS-Cert-Authority'
        }
        WindowsFeature RSAT-ADCS
        {
            Ensure = 'Present'
            Name   = 'RSAT-ADCS'
        }
        AdcsCertificationAuthority CertificateAuthority
        {
            IsSingleInstance = 'Yes'
            Ensure           = 'Present'
            Credential       = $Credential
            CAType           = 'StandaloneRootCA'
            DependsOn        = '[WindowsFeature]ADCS-Cert-Authority'
            KeyLength        = $KeyLength
            ValidityPeriod   = 'Years'
            ValidityPeriodUnits = 15
            HashAlgorithmName    = 'SHA256'
            CACommonName     = $CACommonName
        }

        AdcsCertificationAuthoritySettings CertificateAuthoritySettings
        {
            IsSingleInstance = 'Yes'
            CACertPublicationURLs = $CACertPublicationURLs
            CRLPublicationURLs =  $CRLPublicationURLs
            CRLOverlapUnits = 16
            CRLOverlapPeriod = 'Hours'
            CRLPeriodUnits = 1
            CRLPeriod = 'Years'
            ValidityPeriodUnits = 10
            ValidityPeriod = 'Years'
            DSConfigDN = "CN=$($CACommonName)"
            AuditFilter = @(
                'StartAndStopADCS'
                'BackupAndRestoreCADatabase'
                'IssueAndManageCertificateRequests'
                'RevokeCertificatesAndPublishCRLs'
                'ChangeCASecuritySettings'
                'StoreAndRetrieveArchivedKeys'
                'ChangeCAConfiguration'
            )
            DependsOn        = '[AdcsCertificationAuthority]CertificateAuthority'
        }  
    }
}

$configData = @{
    AllNodes = @(
        @{
            NodeName             = 'localhost';
            PSDscAllowDomainUser = $true
            PsDscAllowPlainTextPassword = $true

        }
    )
}


$Credential = Get-Credential -UserName WIN-VIA7FG20P0I\Administrator -Message "Password please"
Root_CertificationAuthority_Config -Credential $Credential -ConfigurationData $configData -verbose -Wait -Force

<#

Start-DscConfiguration -Path .\Root_CertificationAuthority_Config -verbose -Wait

#>