$clientID = "xxxxxxxxxxxxxxxxxxxxxx" # Replace with your Client ID

connect-PnPOnline -Url "https://contoso-admin.sharepoint.com" -Interactive -ClientID $clientID

# Retrieve all sites
$sites = Get-PnPTenantSite -IncludeOneDriveSites:$false

Write-Host "`nSite Count audited: $($sites.Count)" -ForegroundColor Cyan 

$spoPermissionResult = @()

foreach ($site in $sites) {
    Write-Host "`nSite: $($site.Url)" -ForegroundColor Cyan

# Connect to site
Connect-PnPOnline -Url $site.url -Interactive -ClientID $clientID

    $files = Get-PnPListItem -List Documents | Where-Object { $_.FieldValues["_IpLabelId"] }

# Loop through files and retrieve sensitivity labels
foreach ($file in $files) {

    #$file | Select-Object FieldValues | ConvertTo-Json
    $sensitivityLabel = $file["_IpLabelId"]
    Write-Output "File: $($file['FileRef']) - Sensitivity Label Assigned: $sensitivityLabel, Sensitivity Label Name: $($file['_DisplayName'])"
}



}

