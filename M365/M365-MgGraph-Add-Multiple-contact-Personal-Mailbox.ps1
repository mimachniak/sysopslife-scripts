
<#  
.SYNOPSIS  
    Add to user personal mailbox multiple shared contacts.
.DESCRIPTION  
    Contacts that are shared for users in process of onbording and phone identyfication, will be added to user personal mailbox contacts.
    
.NOTES  
    File Name  : M365-MgGraph-Add-Multiple-contact-Personal-Mailbox.ps1 
    Author     : Michal Machniak  
    Requires   : PowerShell v7.2
    Modules    : None
    Version    : 1.0
.OUTPUTS
    Exchange Online contact in personla contact section.


#>


### Automation Account part 

# Login to Automation Account
Disable-AzContextAutosave -Scope Process

$AzureContext = (Connect-AzAccount -Identity).context
Write-Output -InputObject $AzureContext

$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
Write-Output -InputObject $AzureContext

$ClientSecretCredential = Get-AutomationPSCredential -Name 'P-APP-Graph-Contact' #Credentials declareted in Automation Account



# Connect-MgGraph -Scopes "Contacts.ReadWrite", "User.ReadBasic.All", "User.Read.All", "Directory.Read.All", "User.ReadWrite.All", "Contacts.ReadWrite.Shared" -TenantId 0000000000000000000000000

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Beta.Users
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.PersonalContacts
Import-Module Microsoft.Graph.Beta.PersonalContacts


$instance_number = 100 # Number of paraler operations
$tenantID = "b0027cf-0000-0000-0000-a3d734c00000"

Connect-MgGraph -TenantId $tenantID -ClientSecretCredential $ClientSecretCredential

### Contact parameters ###


$aad_users = Get-MgBetaUser -All | Where-Object {($_.UserType -eq 'Member') -and ($_.UserPrincipalName -notlike "*#EXT#*") -and ($_.AssignedPlans -ne $null) -and ($_.UserPrincipalName -eq "michal.machniak@sys4ops.pl")} 

$aad_users | Foreach-Object -Parallel  {

### Contact parameters ###

$contact_list =  @(

    [pscustomobject]@{

    givenName = 'IT Service Desk'
    surname = '(Français)'
    DisplayName = ' IT Service Desk' ## Nie ulega zmianie
    Department = 'IT'
    EmailAddresses = @(
       @{
          address = "servicedesk@contoso.com"
       }
    )

    BusinessPhones = @(
       "+3310000000"
    )
    Categories = @(
       "HelpDesk"
       )
       
    }
    [pscustomobject]@{

      givenName = 'IT Service Desk'
      surname = '(English)'
      DisplayName = ' IT Service Desk (English)' ## Nie ulega zmianie
      Department = 'IT'
      EmailAddresses = @(
         @{
            address = "servicedesk@contoso.com"
         }
      )
  
      BusinessPhones = @(
         "+3310000000"
      )
      Categories = @(
         "HelpDesk"
         )
         
    }
    [pscustomobject]@{

      givenName = 'IT Service Desk'
      surname = '(Polish)'
      DisplayName = ' IT Service Desk (Polish)' ## Nie ulega zmianie
      Department = 'IT'
      EmailAddresses = @(
         @{
            address = "servicedesk@contoso.com"
         }
      )
  
      BusinessPhones = @(
         "+3310000000"
      )
      Categories = @(
         "HelpDesk"
         )
         
    }
    [pscustomobject]@{

      givenName = 'IT Service Desk'
      surname = '(Deutsch)'
      DisplayName = ' IT Service Desk (Deutsch)' ## Nie ulega zmianie
      Department = 'IT'
      EmailAddresses = @(
         @{
            address = "servicedesk@contoso.com"
         }
      )
  
      BusinessPhones = @(
         "+3310000000"
      )
      Categories = @(
         "HelpDesk"
         )
         
    }
    [pscustomobject]@{

      givenName = 'IT Service Desk'
      surname = ''
      DisplayName = ' IT Service Desk' ## Nie ulega zmianie
      Department = 'IT'
      EmailAddresses = @(
         @{
            address = "servicedesk@contoso.com"
         }
      )
  
      BusinessPhones = @(
         "+3310000000"
      )
      Categories = @(
         "HelpDesk"
         )
         
    }
)

foreach ($contact in $contact_list) {

#Setup varibales

$givenName = $contact.givenName
$surname = $contact.surname
$DisplayName = $contact.DisplayName ## Nie ulega zmianie
$Department = $contact.Department
$EmailAddresses = $contact.EmailAddresses
$BusinessPhones = $contact.BusinessPhones
$Categories = $contact.Categories

#Action that will run in Parallel. Reference the current object via $PSItem and bring in outside variables with $USING:varname
 Write-Output "Checking user: $($_.UserPrincipalName)"


Write-Output "Checking that contact exist : $($DisplayName) in user mailbox: $($_.UserPrincipalName) "
 Get-MgUserContact -UserId $_.Id -Filter "DisplayName eq '$($DisplayName)'"
 $contact_on_mailbox = Get-MgUserContact -UserId $_.Id -Filter "DisplayName eq '$($DisplayName)'" #look for contact
 $contact_on_mailbox


 if ($contact_on_mailbox -eq $null) { 

    Write-Output "Contact will be created : $($DisplayName) in user mailbox: $($_.UserPrincipalName)"
    New-MgUserContact -UserId $_.Id -givenName $($givenName) -surname $($surname) -DisplayName "$($DisplayName)" `
    -Department $Department `
    -EmailAddresses $EmailAddresses `
    -BusinessPhones $BusinessPhones `
    -Categories $Categories

 } else {
    Write-Output "Checking that contact $($DisplayName) need to be updated"
    
    if ($contact_on_mailbox.givenName -ne $givenName) {
       Write-Output "Required update $($DisplayName): givenName "
       Update-MgUserContact -UserId $_.Id -ContactId $contact_on_mailbox.Id -GivenName $givenName
    }
    if ($contact_on_mailbox.Surname -ne $surname) {
       Write-Output "Required update $($DisplayName): Surname"
       Update-MgUserContact -UserId $_.Id -ContactId $contact_on_mailbox.Id -surname $surname
    }
    if ($contact_on_mailbox.DisplayName -ne $DisplayName) {
       Write-Output "Required update $($DisplayName): DisplayName"
       Update-MgUserContact -UserId $_.Id -ContactId $contact_on_mailbox.Id -DisplayName $DisplayName
    }
    if ($contact_on_mailbox.Department -ne $Department) {
       Write-Output "Required update $($DisplayName): Department"
       Update-MgUserContact -UserId $_.Id -ContactId $contact_on_mailbox.Id -Department $Department
    }

    if ($contact_on_mailbox.Categories -ne $Categories) {
       Write-Output "Required update $($DisplayName): Categories"
       Update-MgUserContact -UserId $_.Id -ContactId $contact_on_mailbox.Id -Categories $Categories
    }
     ## Bussines Addresses check 


    ## Bussines Phones

    if ((Compare-Object -ReferenceObject $BusinessPhones -DifferenceObject $contact_on_mailbox.BusinessPhones) -ne $null) {
       Write-Host "Required update: BusinessPhones" -ForegroundColor Red
       Update-MgUserContact -UserId $_.Id -ContactId $contact_on_mailbox.Id -BusinessPhones $BusinessPhones
    }

    ## E-mail adddreses

    $aad_contact_EmailAddresses = @()
    foreach ($aad_contact_mail in $contact_on_mailbox.EmailAddresses)
    {

       $aad_contact_EmailAddresses += @{
          'mail' = "$($aad_contact_mail.Address)"
       }

    }

    $input_contact_EmailAddresses = @()
    foreach ($input_contact_mail in $EmailAddresses)
    {

       $input_contact_EmailAddresses += @{
          'mail' = "$($input_contact_mail.Values)"
       }

    }

    if ((Compare-Object -ReferenceObject $aad_contact_EmailAddresses -DifferenceObject $input_contact_EmailAddresses -Property "mail").SideIndicator -eq "=>") {
       Write-Host "Required update: EmailAddresses" -ForegroundColor Red
       Update-MgUserContact -UserId $_.Id -ContactId $contact_on_mailbox.Id -EmailAddresses $EmailAddresses
    }
    
 }

} # contact matrix


} -ThrottleLimit $instance_number ## Foreach-object - user