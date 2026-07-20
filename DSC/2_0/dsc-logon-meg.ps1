Configuration SetupLogonMessage {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {

        # Sets the Title of the Logon Message
        Registry LogonMessageTitle {
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "legalnoticecaption"
            ValueData = "Security Warning"
            ValueType = "String"
            Ensure    = "Present"
            Force   = $true

        }

        # Sets the Body Text of the Logon Message
        Registry LogonMessageBody {
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "legalnoticetext"
            ValueData = "Authorized access only. All activities are monitored and recorded."
            ValueType = "String"
            Ensure    = "Present"
            DependsOn = "[Registry]LogonMessageTitle"
            Force   = $true
        }
    }
}

# Generate the MOF file
SetupLogonMessage