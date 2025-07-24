# Connect to Microsoft Teams
Connect-MicrosoftTeams

# Prepare array to hold the results
$results = @()

# Get all Teams
$allTeams = Get-Team

foreach ($team in $allTeams) {
    $teamName = $team.DisplayName
    $groupId = $team.GroupId

    # --- Team-level members and owners (standard)
    write-host "Processing team: $teamName"
    $teamUsers = Get-TeamUser -GroupId $groupId
    foreach ($user in $teamUsers) {
        $results += [PSCustomObject]@{
            Team           = $teamName
            Channel        = "<Team Level>" # Indicates membership at team level
            ChannelType    = "Standard"
            User           = $user.User
            Role           = $user.Role
        }
    }

    # --- Channels in the team
    $channels = Get-TeamChannel -GroupId $groupId
    write-host "Processing Channel: $teamName"
    foreach ($channel in $channels) {
        if ($channel.MembershipType -eq "Private") {
            $channelName = $channel.DisplayName
            try {
                $channelUsers = Get-TeamChannelUser -GroupId $groupId -DisplayName $channelName
                foreach ($cUser in $channelUsers) {
                    $results += [PSCustomObject]@{
                        Team           = $teamName
                        Channel        = $channelName
                        ChannelType    = "Private"
                        User           = $cUser.User
                        Role           = $cUser.Role
                    }
                }
            }
            catch {
                Write-Warning "Could not get users for private channel '$channelName': $($_.Exception.Message)"
            }
        }
    }
}

# Display results
$results | Format-Table -AutoSize

# Optional: Export to CSV
$results | Export-Csv -Path "TeamsUsersWithPrivateChannels.csv" -NoTypeInformation -Encoding UTF8
