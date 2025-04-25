

Install-Module -Name ActiveDirectoryCSDsc -Confirm:$false -Force -AllowClobber

#/Requires -module @{Modulename = 'ActiveDirectoryCSDsc'; ModuleVersion = '5.0.0.0'}

Configuration AdcsCertificationAuthority_Sub_enterprise_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        $Credential,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        $CACommonName = 'Sys4Ops Sub CA',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        $DSDomainDN = 'DC=ad,DC=sys4ops,DC=pl',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [ValidateSet('1024','2048','4096')]
        $KeyLength = '4096',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        $CACertPublicationURLs = @(
            '1:file://\\D-W2025-SRV\pki\%1_%3%4.crt'
            '2:C:\Windows\system32\CertSrv\CertEnroll\%1_%3%4.crt'
            '3:http://pki.ad.sys4ops.pl/%1_%3%4.crt'
        ),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        $CRLPublicationURLs = @(
            '67:file://\\D-W2025-SRV\pki\%3%8%9.crl'
            '65:C:\Windows\system32\CertSrv\CertEnroll\%3%8%9.crl'
            '6:http://pki.ad.sys4ops.pl/%3%8%9.crl'
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
            CAType           = 'EnterpriseSubordinateCA'
            DependsOn        = '[WindowsFeature]ADCS-Cert-Authority'
            KeyLength        = $KeyLength
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
            CRLPeriodUnits = 30
            CRLPeriod = 'Days'
            DSDomainDN = $DSDomainDN
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


$Credential = Get-Credential -UserName AD\Administrator -Message "Password please"
AdcsCertificationAuthority_Sub_enterprise_Config -Credential $Credential -ConfigurationData $configData

<#


Start-DscConfiguration -Path .\AdcsCertificationAuthority_Sub_enterprise_Config  -verbose -Wait

#>