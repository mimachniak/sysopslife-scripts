
Configuration 'Install_Feature_Telnet_Client'
{
    param 
    (       
        [System.String]
        $Name = 'Telnet-Client',

        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $IncludeAllSubFeature = $false

    )
    
    Import-DscResource -ModuleName 'PSDscResources'
    
    Node Localhost
    {
        WindowsFeature WindowsFeatureTest
        {
            Name = $Name
            Ensure = $Ensure
            IncludeAllSubFeature = $IncludeAllSubFeature
        }
    }
}

Install_Feature_Telnet_Client