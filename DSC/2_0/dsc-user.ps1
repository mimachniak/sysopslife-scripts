Configuration UserExample
{
    param (
        [System.Management.Automation.PSCredential]
        $PasswordCredential
    )

    Import-DscResource -ModuleName PSDscResources

    Node localhost
    {
        User UserExample
        {
            Ensure   = 'Present'
            UserName = 'SomeUserName'
            Password = $PasswordCredential
        }
    }
}

$configData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowDomainUser = $true
            PSDscAllowPlainTextPassword = $true
        }
    )
}

$Credential = Get-Credential -UserName UserDSC -Message "Password please"

UserExample -PasswordCredential $Credential -ConfigurationData $configData