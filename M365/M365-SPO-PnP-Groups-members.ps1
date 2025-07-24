$clientID = "xxxxxxxxxxxxxxxxxxxxxx" # Replace with your Client ID

connect-PnPOnline -Url "https://contoso-admin.sharepoint.com" -Interactive -ClientID $clientID


$sites = Get-PnPTenantSite -IncludeOneDriveSites:$false

$allSitesGroupMembers = @()

foreach ($site in $sites) {
    Write-Host "`nSite: $($site.Url)" -ForegroundColor Cyan

# Connect to site
Connect-PnPOnline -Url $site.Url -Interactive -ClientID $clientID

# Get all SharePoint groups
$groups = Get-PnPGroup

# Initialize array to store all member objects
$allGroupMembers = @()

# Loop through each group and get members
foreach ($group in $groups) {
    try {
        $members = Get-PnPGroupMember -Group $group

        foreach ($member in $members) {
            $allGroupMembers += [PSCustomObject]@{
                GroupName      = $group.Title
                LoginName      = $member.LoginName
                Email          = $member.Email
                Title          = $member.Title
                PrincipalType  = $member.PrincipalType
                SiteUrl        = $site.Url
                SiteTemplate   = $site.Template
            }
        }
    }
    catch {
        Write-Warning "Could not get members of group '$($group.Title)': $_"
    }
}

$allSitesGroupMembers += $allGroupMembers


}

# Output to screen

# Optional: Export to CSV
$allSitesGroupMembers | Export-Csv -Path "AllGroupMembers_SharePoint_sites_no_teams.csv" -NoTypeInformation