$clientID = "xxxxxxxxxxxxxxxxxxxxxx" # Replace with your Client ID

connect-PnPOnline -Url "https://contoso-admin.sharepoint.com" -Interactive -ClientID $clientID

$sites = Get-PnPTenantSite -IncludeOneDriveSites:$true

$LockState = "ReadOnly" #Accepted values: Unlock, NoAccess, ReadOnly

foreach ($site in $sites) {
    Write-Host "`nSite: $($site.Url)" -ForegroundColor Cyan

    # Connect to site
    Connect-PnPOnline -Url $site.Url -Interactive -ClientID $clientID 

    # Change Lock state

    Set-PnPTenantSite -Url -Url $site.Url -LockState $LockState 


}