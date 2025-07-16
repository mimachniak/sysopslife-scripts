#Requires -Module Az.Accounts
#Requires -Module Az.Storage
#Requires -Module AzTable
#Requires -Module Microsoft.Graph.Authentication
<#
.SYNOPSIS
    Generates a report of inactive users in Azure DevOps (ADO).

.DESCRIPTION
    This script utilizes the Microsoft.Graph.Mail PowerShell module to interact with Microsoft Graph and retrieve information about user activity in Azure DevOps. 
    It identifies users who have been inactive for a specified period and generates a report for administrative purposes.

.REQUIREMENTS
    - Microsoft.Graph / AzTable / Az PowerShell module must be installed and imported.

.NOTES
   Script have functionality:
   - send email to inactive users
   - send email to users who have never logged in  
   - send summary report email of users and licenses
   - log inactive users to Azure Table Storage and after 3 iterations remove user from Azure DevOps organization
   - generate report as output to console
.AUTHOR
    Michal Machniak

.VERSION
    1.0.0
#>

# Global variables for connection

$ManagedIdentityObjectID = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # Replace with your Managed Identity Object ID
$client_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # Replace with your client ID
$SecurePassword = "xxxxxxxxxxxxxxxxxxxx" | ConvertTo-SecureString -AsPlainText -Force
$TenantId = "xxxxxxxxxxxxxxxxxxxxxxxxx" # Replace with your tenant ID

# Login to Azure with Managed Identity or interactive login
try {
    Write-Host "Trying to sign in using Managed Identity..."
    Connect-AzAccount -Identity -AccountId $ManagedIdentityObjectID -ErrorAction Stop
    Write-Host "Successfully signed in with Managed Identity."
}
catch {
    Write-Warning "Managed Identity login failed: $($_.Exception.Message)"
    Write-Host "Falling back to interactive login..."

    try {

            $context = Get-AzContext

            if ($null -ne $context -and $context.Account -ne $null) {
                Write-Host "Azure session is active. Logged in as: $($context.Account)"
            } else {
                Write-Warning "Not connected to Azure. Please run Connect-AzAccount."
                Connect-AzAccount
            }
    }
    catch {
        Write-Error "Interactive login failed: $($_.Exception.Message)"
    }
}


# Set variables
$UserList = @()
$thresholdDateDays = 90 # Days of inactivity to consider a user inactive
$thresholdDate = (Get-Date).AddDays(-$thresholdDateDays) # Date threshold for inactivity
$organization = "XXXXXX"        # Replace with your Azure DevOps organization name
$pat = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # Replace with your PAT

$sendMailToUserInactive = $false # Set to true to send emails to inactive users
$sendMailToUserNotActivated = $false # Set to true to send emails to users who have never logged in
$sendMailSummaryReport = $true # Set to true to send a summary report email
$LogUserInactive = $false # Set to true to log inactive users to Azure Table Storage
$LogUserNotActivated = $false # Set to true to log users who have never logged in
$accountRemovalDays = 30 # Days after which inactive accounts will be removed from Azure DevOps
$autoRemoveUsersFromOrganization = $false # Set to true to automatically remove inactive users from Azure DevOps organization

# Storage account settings for login iteration
$storageAccountName = "xxxxxxx" # Replace with your storage account name
$storageAccountResourceGroupName = "xxxxx" # Replace with your resource group name
$storageAccountTableName = "xxxxxxx" # Replace with your table name

# mial settings
$fromUser = "xxxxxxx@xyz.pl" # Shared mailbox email address
$recipientSummary = "xxxxxx@xxxxxxx" # Email address to send summary report
$supportMail = "xxxxxxx@xxxxxxx" # Support email address for user assistance



if (($LogUserInactive -eq $true) -or ($LogUserNotActivated -eq $true)) {
    Write-Host "Logging inactive users to Azure Table Storage is enabled." -ForegroundColor Green

    # Connect to Azure Table Storage
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $storageAccountResourceGroupName -Name $storageAccountName 
    $context = $storageAccount.Context
    $cloudTable = (Get-AzStorageTable –Name $storageAccountTableName –Context $context).CloudTable

} else {
    Write-Host "Logging inactive users to Azure Table Storage is disabled." -ForegroundColor Yellow
}

if (($sendMailToUserInactive -eq $true) -or ($sendMailToUserNotActivated -eq $true) -or ($sendMailSummaryReport -eq $true)) {
    Write-Host "Sending email is enabled." -ForegroundColor Green

    # Connect to Microsoft Graph
    $Credential = New-Object System.Management.Automation.PSCredential($client_id, $SecurePassword)

    Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $Credential

} else {
    Write-Host "Sending email is disabled." -ForegroundColor Yellow
}



# Azure DevOps API URL for listing users
$url = "https://vsaex.dev.azure.com/$organization/_apis/userentitlements?api-version=7.1-preview.1"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))

# Send request
$response = Invoke-RestMethod -Uri $url -Method Get -Headers @{
    Authorization = "Basic $base64AuthInfo"
}


# Process and display the response

$response.value | ForEach-Object {
    $UserList += [PSCustomObject]@{
        DisplayName    = $_.user.displayName
        Email          = $_.user.mailAddress
        LastAccessDate = if ($_.lastAccessedDate -eq "01.01.0001 00:00:00") 
            { 
                "Never"
            } else 
            { 
                $_.lastAccessedDate
            }
        License        = $_.accessLevel.licenseDisplayName
        Action = if ($_.lastAccessedDate -eq "01.01.0001 00:00:00") 
            { 
                "NotActivated"
            } elseif ($_.lastAccessedDate -lt $thresholdDate) {
                "SendRequestToUser"
            } else 
            { 
                "NoActionNeeded" 
            }
        Organization   = $organization
        Iteration = 1
    }
}


foreach ($user in $UserList) {
    # Check if the user has not logged in for more than 90 days
    if ($user.Action -eq "SendRequestToUser") {

        if ($sendMailToUserInactive) {
        write-host "User $($user.DisplayName) with action $($user.Action) in organization: $organization - send mail" -ForegroundColor Green
        
        $emailParams = @{
        Message = @{
            Subject = "AzureDevOps Account Inactivity ($thresholdDateDays days) Notification in organization $organization"
            Body = @{
                ContentType = "HTML"
                Content = @"
                    <!-- English Section -->
                    <p><b>Dear $($user.DisplayName),</b></p>

                    <p>Your account has not been accessed for more than <b>$thresholdDateDays days</b>.</p>

                    <p>Please log in as soon as possible to avoid account removal in the next <b>$accountRemovalDays days</b>.</p>

                    <p>
                        <a href='https://dev.azure.com/$organization'>Click here to log in</a><br/>
                        or contact <a href='mailto:$supportMail'>IT support</a> if you need assistance.
                    </p>

                    <p><b>Switching between Azure DevOps tenants:</b><br/>
                    1. Sign out of Azure DevOps completely.<br/>
                    2. Go to <a href="https://dev.azure.com/">https://dev.azure.com/</a> and sign in again.<br/>
                    3. Select the correct directory or organization when prompted.
                    </p>

                    <p>Regards,<br/>IT Department</p>

                    <hr style="margin:30px 0;"/>

                    <!-- Polish Section -->
                    <p><b>Szanowny/a $($user.DisplayName),</b></p>

                    <p>Twoje konto nie było używane przez ponad <b>$thresholdDateDays dni</b>.</p>

                    <p>Zaloguj się jak najszybciej, aby uniknąć usunięcia konta w ciągu <b>$accountRemovalDays dni</b>.</p>

                    <p>
                        <a href='https://dev.azure.com/$organization'>Kliknij tutaj, aby się zalogować</a><br/>
                        lub skontaktuj się z <a href='mailto:$supportMail'>wsparciem IT</a>, jeśli potrzebujesz pomocy.
                    </p>

                    <p><b>Jak przełączyć się między dzierżawcami (tenantami) Azure DevOps:</b><br/>
                    1. Wyloguj się całkowicie z Azure DevOps.<br/>
                    2. Przejdź do <a href="https://aex.dev.azure.com/me?mkt=en-US">https://aex.dev.azure.com/me?mkt=en-US</a> i zaloguj się ponownie.<br/>
                    3. Wybierz odpowiednią organizację lub katalog, gdy zostaniesz o to poproszony.
                    </p>

                    <p>Pozdrawiamy,<br/>Dział IT</p>
"@
            }
            ToRecipients = @(
                @{
                    EmailAddress = @{
                        Address = $user.Email
                    }
                }
            )
        }
        SaveToSentItems = $true
        }
         try {
            Write-Host "Attempting to send email to user..." -ForegroundColor Green

            Send-MgUserMail -UserId $fromUser -BodyParameter $emailParams

            } catch {
                Write-Host "Error sending email to user: $_" -ForegroundColor Red
            }

        } 
        
        if ($LogUserInactive) {

            Write-Host "No email sent for user $($user.DisplayName) with action $($user.Action) in organization: $organization" -ForegroundColor Yellow

            $hashtableUser = @{}; $user.PSObject.Properties | ForEach-Object { $hashtableUser[$_.Name] = $_.Value }

            $userRow = Get-AzTableRow -table $cloudTable -customFilter "(Email eq '$($user.Email)')"

            if($userRow) {
                Write-Host "User $($user.DisplayName) with action $($user.Action) in organization: $organization already exists in table, skipping..." -ForegroundColor Yellow
                
                if ($userRow.Iteration -lt 3) {

                    $userRow.Iteration += 1
                    # To commit the change, pipe the updated record into the update cmdlet.
                    Update-AzTableRow -Table $cloudTable -entity $userRow
                } else {
                    Write-Host "User $($user.DisplayName) with action $($user.Action) in organization: $organization has reached the maximum iteration, skipping..." -ForegroundColor Yellow

                    if ($autoRemoveUsersFromOrganization) {
                        Write-Host "Removing user $($user.DisplayName) from organization: $organization" -ForegroundColor Red
                        # Remove user from Azure DevOps organization
                        $removeUrl = "https://vsaex.dev.azure.com/$organization/_apis/userentitlements/$($user.Email)?api-version=7.1-preview.1"

                        try {

                            Invoke-RestMethod -Uri $removeUrl -Method Delete -Headers @{Authorization = "Basic $base64AuthInfo"}
                        }
                        catch {
                            Write-Host "Error Removing user from organization $organization -: $_" -ForegroundColor Red
                        }


                    } else {
                        Write-Host "Auto removal is disabled, skipping removal for user $($user.DisplayName)" -ForegroundColor Yellow
                    }
                }
             
            } else {

                Add-AzTableRow -Table $cloudTable -Property $hashtableUser -partitionKey "PSUsers" -rowKey (New-Guid)
            }

        }


    } # if inactive 90 days

    if ($user.Action -eq "NotActivated") {
        # If the user has never logged in, remove them from the list
        if ($sendMailToUserNotActivated) {

        write-host "User $($user.DisplayName) with action $($user.Action) in organization: $organization - send mail" -ForegroundColor Green
        $emailParams = @{
        Message = @{
            Subject = "AzureDevOps Account NOT active Notification in organization $organization"
            Body = @{
                ContentType = "HTML"
                Content = @"
                <!-- English Section -->
                <p><b>Dear $($user.DisplayName),</b></p>

                <p>Your Azure DevOps account has been marked as <b>inactive</b> due to extended inactivity.</p>

                <p>If you still need access, please log in within the next <b>$accountRemovalDays days</b> to avoid permanent removal.</p>

                <p>
                    <a href='https://dev.azure.com/$organization'>Click here to log in</a><br/>
                    or contact <a href='mailto:$supportMail'>IT support</a> if you need assistance.
                </p>

                <p><b>Switching between Azure DevOps tenants:</b><br/>
                1. Sign out of Azure DevOps completely.<br/>
                2. Go to <a href="https://aex.dev.azure.com/me?mkt=en-US">https://aex.dev.azure.com/me?mkt=en-US</a> and sign in again.<br/>
                3. Select the correct directory or organization when prompted.
                </p>

                <p>Regards,<br/>IT Department</p>

                <hr style="margin:30px 0;"/>

                <!-- Polish Section -->
                <p><b>Szanowny/a $($user.DisplayName),</b></p>

                <p>Twoje konto w Azure DevOps zostało oznaczone jako <b>nieaktywne</b> z powodu długotrwałego braku aktywności.</p>

                <p>Jeśli nadal potrzebujesz dostępu, zaloguj się w ciągu <b>$accountRemovalDays dni</b>, aby uniknąć trwałego usunięcia konta.</p>

                <p>
                    <a href='https://dev.azure.com/$organization'>Kliknij tutaj, aby się zalogować</a><br/>
                    lub skontaktuj się z <a href='mailto:$supportMail'>wsparciem IT</a>, jeśli potrzebujesz pomocy.
                </p>

                <p><b>Jak przełączyć się między dzierżawcami (tenantami) Azure DevOps:</b><br/>
                1. Wyloguj się całkowicie z Azure DevOps.<br/>
                2. Przejdź do <a href="https://aex.dev.azure.com/me?mkt=en-US">https://aex.dev.azure.com/me?mkt=en-US</a> i zaloguj się ponownie.<br/>
                3. Wybierz odpowiednią organizację lub katalog, gdy zostaniesz o to poproszony.
                </p>

                <p>Pozdrawiamy,<br/>Dział IT</p>

"@
            }
            ToRecipients = @(
                @{
                    EmailAddress = @{
                        Address = $user.Email
                    }
                }
            )
        }
        SaveToSentItems = $true
     }
     # Send the email as the shared mailbox
    try {
        Write-Host "Attempting to send email to user...." -ForegroundColor Green

        Send-MgUserMail -UserId $fromUser -BodyParameter $emailParams

        } catch {
            Write-Host "Error sending email to user: $_" -ForegroundColor Red
        }

        } 
    
        if ($LogUserNotActivated) {
            write-host "No email sent for user $($user.DisplayName) with action $($user.Action) in organization:$organization" -ForegroundColor Red

            $hashtableUser = @{}; $user.PSObject.Properties | ForEach-Object { $hashtableUser[$_.Name] = $_.Value }

            $userRow = Get-AzTableRow -table $cloudTable -customFilter "(Email eq '$($user.Email)')"

                if($userRow) {
                    Write-Host "User $($user.DisplayName) with action $($user.Action) in organization: $organization already exists in table, skipping..." -ForegroundColor Yellow
                    
                    if ($userRow.Iteration -lt 3) {

                        $userRow.Iteration += 1
                        # To commit the change, pipe the updated record into the update cmdlet.
                        Update-AzTableRow -Table $cloudTable -entity $userRow
                    } else {
                        Write-Host "User $($user.DisplayName) with action $($user.Action) in organization: $organization has reached the maximum iteration, skipping..." -ForegroundColor Yellow

                        if ($autoRemoveUsersFromOrganization) {
                            Write-Host "Removing user $($user.DisplayName) from organization: $organization" -ForegroundColor Red
                            # Remove user from Azure DevOps organization
                            $removeUrl = "https://vsaex.dev.azure.com/$organization/_apis/userentitlements/$($user.Email)?api-version=7.1-preview.1"

                            try {

                                Invoke-RestMethod -Uri $removeUrl -Method Delete -Headers @{Authorization = "Basic $base64AuthInfo"}
                            }
                            catch {
                                    Write-Host "Error Removing user from organization $organization -: $_" -ForegroundColor Red
                                }


                            } else {
                                Write-Host "Auto removal is disabled, skipping removal for user $($user.DisplayName)" -ForegroundColor Yellow
                            }
                        }
                
                } else {

                    Add-AzTableRow -Table $cloudTable -Property $hashtableUser -partitionKey "PSUsers" -rowKey (New-Guid)
                }

        }
    } 




} # loop user

# Construct the email for summary report

if ($sendMailSummaryReport) {

    Write-Host "Sending summary report email for organization: $organization" -ForegroundColor Green

    $emailParams = @{
        Message = @{
            Subject = "Azure DevOps User Activity Summary Report for organization $organization"
            Body = @{
                ContentType = "HTML"
                Content = $UserList | Sort-Object LastAccessDate |  ConvertTo-Html -Property DisplayName, Email, LastAccessDate, License, Action -Fragment | Out-String
            }
            ToRecipients = @(
                @{
                    EmailAddress = @{
                        Address = $recipientSummary
                    }
                }
            )
        }
        SaveToSentItems = $true
    }

    # Send the email as the shared mailbox

    try {
        Write-Host "Attempting to send summary report email..." -ForegroundColor Green

        Send-MgUserMail -UserId $fromUser -BodyParameter $emailParams

    } catch {
        Write-Host "Error sending summary report email: $_" -ForegroundColor Red
    }
    
    } else {
    Write-Host "No summary report email sent for organization: $organization" -ForegroundColor Green
    # Display the user list in a table format
    Write-Host "Displaying user list for organization: $organization" -ForegroundColor Green
    $UserList | Format-Table -AutoSize -Property DisplayName, Email, LastAccessDate, License, Action, Organization, Iteration
}