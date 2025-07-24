Import-Module Microsoft.Graph
Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All", "AppRoleAssignment.Read.All"

# Get all service principals
Write-Host "Fetching service principals..." -ForegroundColor Cyan
$servicePrincipals = Get-MgServicePrincipal -All
$spMap = @{}
foreach ($sp in $servicePrincipals) {
    $spMap[$sp.AppId] = $sp
}

# Get all applications
Write-Host "Fetching application registrations..." -ForegroundColor Cyan
$appRegistrations = Get-MgApplication -All

# Process each app
$results = foreach ($app in $appRegistrations) {
    $platforms = @()

    if ($app.Web) {
        $platforms += [PSCustomObject]@{
            PlatformType             = 'Web'
            RedirectUris             = ($app.Web.RedirectUris -join ', ')
            LogoutUrl                = $app.Web.LogoutUrl
            ImplicitGrantIdToken     = $app.Web.ImplicitGrantSettings.EnableIdTokenIssuance
            ImplicitGrantAccessToken = $app.Web.ImplicitGrantSettings.EnableAccessTokenIssuance
        }
    }

    if ($app.Spa) {
        $platforms += [PSCustomObject]@{
            PlatformType             = 'SPA'
            RedirectUris             = ($app.Spa.RedirectUris -join ', ')
            LogoutUrl                = $null
            ImplicitGrantIdToken     = $app.Spa.ImplicitGrantSettings.EnableIdTokenIssuance
            ImplicitGrantAccessToken = $app.Spa.ImplicitGrantSettings.EnableAccessTokenIssuance
        }
    }

    if ($app.PublicClient) {
        $platforms += [PSCustomObject]@{
            PlatformType             = 'PublicClient'
            RedirectUris             = ($app.PublicClient.RedirectUris -join ', ')
            LogoutUrl                = $null
            ImplicitGrantIdToken     = $null
            ImplicitGrantAccessToken = $null
        }
    }

    # API permissions
    $permissions = @()
    foreach ($resource in $app.RequiredResourceAccess) {
        $resourceAppId = $resource.ResourceAppId
        $sp = $spMap[$resourceAppId]
        $resourceName = if ($sp) { $sp.DisplayName } else { $resourceAppId }

        foreach ($perm in $resource.ResourceAccess) {
            $permId   = $perm.Id
            $permType = $perm.Type
            $permName = $null

            if ($permType -eq "Scope" -and $sp) {
                $permName = ($sp.Oauth2Permissions | Where-Object { $_.Id -eq $permId }).Value
            } elseif ($permType -eq "Role" -and $sp) {
                $permName = ($sp.AppRoles | Where-Object { $_.Id -eq $permId }).Value
            }

            $permissions += [PSCustomObject]@{
                Resource        = $resourceName
                ResourceAppId   = $resourceAppId
                PermissionType  = if ($permType -eq "Scope") { "Delegated" } else { "Application" }
                PermissionId    = $permId
                PermissionName  = $permName
            }
        }
    }

    # Get service principal for this app (to check assignment requirements)
    # Get service principal for this app
    $spForApp = $servicePrincipals | Where-Object { $_.AppId -eq $app.AppId }

    $assignmentRequired = $false
    $assignedUsers = @()
    $visibleToUsers = $true  # Default to true

    if ($spForApp) {
        $assignmentRequired = $spForApp.AppRoleAssignmentRequired

        # Determine visibility: if "HideApp" tag exists, it's NOT visible
        if ($spForApp.Tags -contains "HideApp") {
            $visibleToUsers = $false
        }

        if ($assignmentRequired) {
            $assignments = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $spForApp.Id -All
            foreach ($assignment in $assignments) {
                $user = Get-MgDirectoryObject -DirectoryObjectId $assignment.PrincipalId
                $assignedUsers += $user.AdditionalProperties.displayName
            }
        }
    }


    # Final output
    [PSCustomObject]@{
        DisplayName           = $app.DisplayName
        AppId                 = $app.AppId
        ObjectId              = $app.Id
        SignInAudience        = $app.SignInAudience
        AssignmentRequired    = $assignmentRequired
        AssignedUsers         = $assignedUsers
        VisibleToUsers        = $visibleToUsers
        Authentication        = $platforms
        ApiPermissions        = $permissions
    }
}

# Output to screen
$results

# Export
$results | ConvertTo-Json -Depth 6 | Out-File "AppAuthApiPermissionsWithAssignments.json"
