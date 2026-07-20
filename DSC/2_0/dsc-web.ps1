


Configuration web_iis_install {


Import-DscResource -Module PSDscResources


        WindowsFeature IIS
        {
            Ensure                  = 'Present'
            Name                    = 'Web-Server'
        }

        WindowsFeature IIS_Managment_tools
        {
            Ensure                  = 'Present'
            Name                    = 'Web-Mgmt-Console'
            DependsOn               = '[WindowsFeature]IIS'
        }

}

web_iis_install