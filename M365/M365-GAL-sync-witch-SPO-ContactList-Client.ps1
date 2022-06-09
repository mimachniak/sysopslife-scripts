
<#  
.SYNOPSIS  
    Get user contact information and put in SPO list.
.DESCRIPTION  
    Get data from Office 365 Users and create global contact list in SPO.
    
.NOTES  
    File Name  : M365-ContactList.ps1 
    Author     : Michal Machniak  
    Requires   : PowerShell v5.1
    Modules    : None
    Version    : 1.0
.OUTPUTS
    Sharepoint Online custom list. With columns:


.EXAMPLE
Example CmdletBinding

-spoSiteName Test `
-spoListName TestList `
-spoTenantId 435634636-eabf-47ea-998f-15c7f956366`
-spoClient_id d74552343-7400-4b48-8dde-74r23553252`
-spoClient_secret ********************************`
-aadTenantId d4520405-eabf-47ea-998f-15c7f956366 `
-aadClient_id d77bcd93-7400-4b48-8dde-74r23553252 `
-aadClient_secret ***************************** `

.EXAMPLE
Data for Sharepoint item in json
        {
            "businessPhones": [
                "+48 17 555 1122"
            ],
            "displayName": "Jan Kowalski",
            "givenName": "Jan",
            "jobTitle": "IT HelpDesk",
            "mail": "jan.kowalski@sys4ops.pl",
            "mobilePhone": "+48 666555111",
            "officeLocation": null,
            "preferredLanguage": null,
            "surname": "Kowalski",
            "userPrincipalName": "jan.kowalski@sys4ops.pl",
            "id": "1c227ac6-51a6-401e-bd39-96eee6270b0f"
        }

    SharePoint Online List Column

        DisplayName	Single line of text	
        givenName	Single line of text	
        surName	Single line of text	
        userPrincipalName	Single line of text
        mail	Single line of text	
        JobTittle	Single line of text	
        Office	Single line of text	
        Company	Single line of text	
        Department	Single line of text	
        City	Single line of text	
        StreetAddress	Single line of text	
        Province	Single line of text
        postalCode   Single line of text
        Country	Single line of text	
        Mobile	Single line of text	
        OfficePhoneNumber	Single line of text	
#>

#...................................
# Objects
#...................................


[CmdletBinding()]
Param (
    
    # Sharepoint list access tenant 

    [Parameter(Mandatory=$True,HelpMessage="Friendly name of SharePoint site where list is located. .")]
    [string]$spoSiteName,

    [Parameter(Mandatory=$True,HelpMessage="Friendly name of SharePoint list.")]
    [string]$spoListName,

    [Parameter(Mandatory=$True,HelpMessage="Office 365 tenant ID with SPO List.")]
    [string]$spoTenantId,

    [Parameter(Mandatory=$True,HelpMessage="Azure Active Directory Application ID with SPO List.")]
    [string]$spoClient_id,

    [Parameter(Mandatory=$True,HelpMessage="Azure Active Directory Application client secret with SPO List.")]
    [string]$spoClient_secret,

    # Active Directory Tenant access

    [Parameter(Mandatory=$True,HelpMessage="Office 365 tenant ID with Azur AD users.")]
    [string]$aadTenantId,

    [Parameter(Mandatory=$True,HelpMessage="Azure Active Directory Application ID.")]
    [string]$aadClient_id,

    [Parameter(Mandatory=$True,HelpMessage="Azure Active Directory Application client secret.")]
    [string]$aadClient_secret

)

#...................................
# Global Settings
#...................................

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


#...................................
# Record session to file
#...................................

$TranscriptFilePath = "F:\Scripts\GAl-Sync"
    if (!(test-path ($TranscriptFilePath ))) {

        $TranscriptFilePath = $PWD.Path

    }
$TranscriptFile = $TranscriptFilePath+'\'+$tenantName+'.txt'
$TranscriptFile

Start-Transcript -Path "$TranscriptFile"

write-host "Log file crated in : "$PSScriptRoot


#...................................
## Graph API  Operations##
#...................................

#..............SharePoint.....................


Write-Host "Data for connect ot SPO Tenant"

    $spoTenantId
    $spoClient_id

Write-Host "Connect to tenant [$spoTenantId] graph API witch SharePoint List"

    $graphUri_spo = "https://login.microsoftonline.com/$spoTenantId/oauth2/v2.0/token"


    $graphbody_spo = @{
        client_id     = $spoClient_id
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $spoClient_secret
        grant_type    = "client_credentials"
    }

#    $graphtokenRequest = Invoke-WebRequest -Method Post -Uri $graphUri -ContentType "application/x-www-form-urlencoded" -Body $graphbody -UseBasicParsing

Write-Verbose "Graph API access token generating"


# Get OAuth 2.0 Token
$graphtokenRequest_spo = try {

    Invoke-WebRequest -Method Post -Uri $graphUri_spo -ContentType "application/x-www-form-urlencoded" -Body $graphbody_spo -UseBasicParsing

    Write-Host "Graph API access token generated"
}
catch [System.Net.WebException] {

    Write-Warning "Exception was caught: $($_.Exception.Message)"
    
}

    $graphtoken_spo = ($graphtokenRequest_spo.Content | ConvertFrom-Json).access_token


#..............AAD.....................

Write-Host "Data for connect tt AAD Tenant"

    $aadTenantId
    $aadClient_id

Write-Host "Connect to tenant [$aadTenantId] graph API Azure Active Directory Users"

    $graphUri_aad = "https://login.microsoftonline.com/$aadTenantId/oauth2/v2.0/token"


    $graphbody_aad = @{
        client_id     = $aadClient_id
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $aadClient_secret
        grant_type    = "client_credentials"
    }

#    $graphtokenRequest = Invoke-WebRequest -Method Post -Uri $graphUri -ContentType "application/x-www-form-urlencoded" -Body $graphbody -UseBasicParsing

Write-Verbose "Graph API access token generating"


# Get OAuth 2.0 Token
$graphtokenRequest_aad = try {

    Invoke-WebRequest -Method Post -Uri $graphUri_aad -ContentType "application/x-www-form-urlencoded" -Body $graphbody_aad -UseBasicParsing

    Write-Host "Graph API access token generated"
}
catch [System.Net.WebException] {

    Write-Warning "Exception was caught: $($_.Exception.Message)"
    
}

    $graphtokenRequest_aad = ($graphtokenRequest_aad.Content | ConvertFrom-Json).access_token


#...................................
# SPO settings
#...................................

# SPO FQDN Hostname retrive for other acctions.

Write-Verbose "Sharepoint Online hostname"

    $spoRootSite = Invoke-WebRequest -Method Get -Uri "https://graph.microsoft.com/v1.0/sites/root"  -ContentType "application/json" -Headers @{Authorization = "Bearer $graphtoken_spo"} -ErrorAction Stop
    $spoRootSite = $spoRootSite | ConvertFrom-Json
    $spoRootSiteHostName = $spoRootSite.siteCollection.hostname

Write-Host "SPO Hostname: [$spoRootSiteHostName]"

# SPO Site properties - ID for other actions

Write-Verbose "Sharepoint Online Site Data" 

    $spoSiteUri = "https://graph.microsoft.com/v1.0/sites/"+$spoRootSiteHostName+":/sites/$spoSiteName"
    $spoSite = Invoke-WebRequest -Method Get -Uri $spoSiteUri  -ContentType "application/json" -Headers @{Authorization = "Bearer $graphtoken_spo"} -ErrorAction Stop
    $spoSite = $spoSite | ConvertFrom-Json
    $spoSiteId = $spoSite.id

Write-Host "SPO Site ID: [$spoSiteId]"

# SPO List ID on dedicate site for other actions.

Write-Verbose "Sharepoint Online List Data" 

Write-Verbose "https://graph.microsoft.com/v1.0/sites/$spoSiteId/lists/$spoListName"

    $spoSiteListUri = "https://graph.microsoft.com/v1.0/sites/$spoSiteId/lists/$spoListName"
    $spoSiteList = Invoke-WebRequest -Method Get -Uri $spoSiteListUri  -ContentType "application/json" -Headers @{Authorization = "Bearer $graphtoken_spo"} -ErrorAction Stop
    $spoSiteList = $spoSiteList | ConvertFrom-Json
    $spoListId = $spoSiteList.id

Write-Host "SPO List ID: [$spoListId]"

## Report Settings and actions
#...................................
# Active Directory Users over Graph
#...................................

# Loading User to Object

$m365Users = @()

# Filter only Members accounts

$url = 'https://graph.microsoft.com/v1.0/users?$select=accountEnabled,assignedLicenses,businessPhones,city,companyName,state,country,displayName,department,givenName,jobTitle,mail,mobilePhone,postalCode,preferredLanguage,streetAddress,surname,userType,userPrincipalName&$filter=userType eq ''member'''
 
    While ($url -ne $Null) {
        $data = (Invoke-WebRequest -Method Get -Uri $url -Headers @{Authorization = "Bearer $graphtoken_aad"}) | ConvertFrom-Json
        $m365Users += $data.Value
        $url = $data.'@Odata.NextLink'
    }
 
write-host "List of users loaded: "$m365Users.Count


# Items counting starting Index

$m365UsersUpdated = 0
$m365UsersAdded = 0
$m365UsersSkipped = 0

# Procced each message 

foreach ($m365User in $m365Users) 
{


    $displayName = $m365User.displayName
    $userPrincipalName = $m365User.userPrincipalName
    $givenName = $m365User.givenName
    $surName = $m365User.surname


    $businessPhones = $m365User.businessPhones -replace (' ','')
    $mobilePhone = $m365User.mobilePhone

    $officeLocation = $m365User.officeLocation
    $companyName = $m365User.companyName
    $country = $m365User.country
    $state = $m365User.state
    $city = $m365User.city
    $streetAddress = $m365User.streetAddress
    $postalCode = $m365User.postalCode


    $JobTittle = $m365User.jobTitle
    $department = $m365User.department
    $mail  = $m365User.mail    

    
    $TestExisting = try {

        Invoke-RestMethod -Method GET -Uri "https://graph.microsoft.com/v1.0/sites/$spoSiteId/lists/$spoListId/items?expand=fields&filter=((fields/userPrincipalName eq '$($userPrincipalName)'))" -Headers @{Authorization = "Bearer $graphtoken_spo"} -ErrorAction Stop

        }
        catch [System.Net.WebException] {
        
            Write-Warning "Exception was caught: $($_.Exception.Message)" 
            
        }

       if ($($TestExisting.value.fields.userPrincipalName) -ne $null) {

            $spoSiteContactId = $TestExisting.value.fields.id

            $requestItemProperties = [PSCustomObject]@{} # PS Custom object null

            Write-Host "Prepare to [UPDATE] User witch ID: [$userPrincipalName]" -ForegroundColor Yellow


            if ($displayName -ne $($TestExisting.value.fields.Title) ) { # Title is default SharePoiny column name adn connot be change

                Write-Host "[UPDATE] displayName will be change form: $($TestExisting.value.fields.Title) to $displayName" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Title' -Value "$displayName"
            }

            if ($givenName -ne $($TestExisting.value.fields.givenName) ) {

                Write-Host "[UPDATE] givenName will be change form: $($TestExisting.value.fields.givenName) to $givenName" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'givenName' -Value "$givenName"
            }

            if ($surName -ne $($TestExisting.value.fields.surName) ) {

                Write-Host "[UPDATE] surName will be change form: $($TestExisting.value.fields.surName) to $surName" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'surName' -Value "$surName"
            }

            if ($userPrincipalName -ne $($TestExisting.value.fields.userPrincipalName) ) {

                Write-Host "[UPDATE] userPrincipalName will be change form: $($TestExisting.value.fields.userPrincipalName) to $userPrincipalName" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'userPrincipalName' -Value "$userPrincipalName"
            }

            if ($mail -ne $($TestExisting.value.fields.mail) ) {

                Write-Host "[UPDATE] mail will be change form: $($TestExisting.value.fields.mail) to $mail" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'mail' -Value "$mail"
            }

            ############### Organization Data #######################

            if ($JobTittle -ne $($TestExisting.value.fields.JobTittle) ) {

                Write-Host "[UPDATE] JobTittle will be change form: $($TestExisting.value.fields.JobTittle) to $JobTittle" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'JobTittle' -Value "$JobTittle"
            }

            if ($department -ne $($TestExisting.value.fields.Department) ) {

                Write-Host "[UPDATE] Department will be change form: $($TestExisting.value.fields.Department) to $department" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Department' -Value "$department"
            }

            if ($companyName -ne $($TestExisting.value.fields.Company) ) {

                Write-Host "[UPDATE] companyName will be change form: $($TestExisting.value.fields.companyName) to $companyName" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Company' -Value "$companyName"
            }

            ############### Phones #######################

            if ($businessPhones -ne $($TestExisting.value.fields.OfficePhoneNumber) ) {

                Write-Host "[UPDATE] businessPhones will be change form: $($TestExisting.value.fields.OfficePhoneNumber) to $businessPhones" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'OfficePhoneNumber' -Value "$businessPhones"
            }

            if ($mobilePhone -ne $($TestExisting.value.fields.Mobile) ) {

                Write-Host "[UPDATE] mobilePhone will be change form: $($TestExisting.value.fields.Mobile) to $mobilePhone" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Mobile' -Value "$mobilePhone"
            }

            ############### Addresess #######################

            if ($officeLocation -ne $($TestExisting.value.fields.Office) ) {

                Write-Host "[UPDATE] office will be change form: $($TestExisting.value.fields.Office) to $officeLocation" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Office' -Value "$officeLocation"
            }

            if ($country -ne $($TestExisting.value.fields.Country) ) {

                Write-Host "[UPDATE] country will be change form: $($TestExisting.value.fields.Country) to $country" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Country' -Value "$country"
            }

            if ($state -ne $($TestExisting.value.fields.Province) ) {

                Write-Host "[UPDATE] state will be change form: $($TestExisting.value.fields.Province) to $state" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Province' -Value "$state"
            }

            if ($city -ne $($TestExisting.value.fields.City) ) {

                Write-Host "[UPDATE] City will be change form: $($TestExisting.value.fields.City) to $city" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'City' -Value "$city"
            }

            if ($streetAddress -ne $($TestExisting.value.fields.StreetAddress) ) {

                Write-Host "[UPDATE] streetAddress will be change form: $($TestExisting.value.fields.StreetAddress) to $streetAddress" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'StreetAddress' -Value "$streetAddress"
            }

            if ($postalCode -ne $($TestExisting.value.fields.postalCode) ) {

                Write-Host "[UPDATE] postalCode will be change form: $($TestExisting.value.fields.postalCode) to $postalCode" -ForegroundColor Yellow
                Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'postalCode' -Value "$postalCode"
            }

            $spoRequestBody = @{ fields = $requestItemProperties
            } | ConvertTo-Json # Data to Input in list convert to json request


            $spoRequestBody

            $spoUpdateItemToList = try {
            
                Invoke-WebRequest -Method Patch -Uri "https://graph.microsoft.com/v1.0/sites/$spoSiteId/lists/$spoListId/items/$spoSiteContactId"  -ContentType "application/json" -Headers @{Authorization = "Bearer $graphtoken"} -Body $spoRequestBody -ErrorAction Stop
                
            }
            catch [System.Net.WebException] {
            
                Write-Warning "Exception was caught: $($_.Exception.Message)" 
                
            }


            $m365UsersUpdated+= 1

        } # If exist in SharePoint List
        else {

            if ($m365User.assignedLicenses -ne $null) {


                # write-host "Checking user $($m365User.userPrincipalName)" -ForegroundColor Green
    
                $m365User_mailboxSettings_uri = "https://graph.microsoft.com/v1.0/users/$($m365User.userPrincipalName)/mailboxSettings"
                $m365User_mailboxSettings = Invoke-WebRequest -Method Get -Uri $m365User_mailboxSettings_uri  -ContentType "application/json" -Headers @{Authorization = "Bearer $graphtoken"} -ErrorAction Stop | ConvertFrom-Json
                
                if ($m365User_mailboxSettings.userPurpose -eq "user") {
    
                    write-host "User have mailbox and will be added to list $($m365User.userPrincipalName)" -ForegroundColor Green 
                        
                    $requestItemProperties = [PSCustomObject]@{}
    
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Title' -Value "$displayName" # Title is default SharePoiny column name adn connot be change
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'givenName' -Value "$givenName"
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'surName' -Value "$surName"
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'userPrincipalName' -Value $userPrincipalName
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'mail' -Value $mail
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'JobTittle' -Value "$JobTittle"
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Office' -Value "$officeLocation"
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Company' -Value "$companyName"
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Department' -Value "$department"
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'City' -Value "$city"
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'StreetAddress' -Value "$streetAddress"
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Province' -Value "$state"
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'postalCode' -Value "$postalCode"
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Country' -Value "$country"
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'Mobile' -Value "$mobilePhone"
                        Add-Member -InputObject $requestItemProperties -MemberType 'NoteProperty' -Name 'OfficePhoneNumber' -Value "$businessPhones"
    
                    $spoRequestBody = @{ fields = $requestItemProperties
                    } | ConvertTo-Json # Data to Input in list convert to json reques
    
                     $spoAddItemToList = try {
    
                        Invoke-WebRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/sites/$spoSiteId/lists/$spoListId/items"  -ContentType "application/json" -Headers @{Authorization = "Bearer $graphtoken_spo"} -Body $spoRequestBody -ErrorAction Stop
                    
                    }
                    catch [System.Net.WebException] {
                    
                        Write-Warning "Exception was caught: $($_.Exception.Message)" 
                        
                    } 
            
                    $m365UsersAdded += 1
         
                } # Only User's Mailbox Type
                else {
    
                    write-host "User don't have user type mailbox $($m365User.userPrincipalName)" -ForegroundColor Yellow
    
                } # Not User Mailbox

            } # Only users witch licences

        } # If NOT exist in SharePoint List


 #
} # Loop close for each messeage in data set

Write-Host "Report Data ready to export ..."
Write-Host "Number of Users exported: $($m365Users.Count)"
Write-Host "Number of Users added to list: $m365UsersAdded"
Write-Host "Number of Users updated to list: $m365UsersUpdated"
Write-Host "Number of Users skipped to list: $m365UsersSkipped"

Stop-Transcript