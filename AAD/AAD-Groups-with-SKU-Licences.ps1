<#  
.SYNOPSIS  
    Create Azure Active Directory and assign license to group
.DESCRIPTION  
    Script will create group with dedicated naming convention, list all SKU available in tenant,
    assigned SKU license to group.
 
    
.NOTES  
    File Name  : AAD-Groups-with-SKU-License.ps1 
    Author     : Michal Machniak  
    Requires   : PowerShell V5.1
    Modules    : AzureAD and AzureADLicensing
.LINK

    Github: https://github.com/mimachniak/sysopslife-scripts
    Site: https://sysopslife.sys4ops.pl/
    Modules links:
        AzureADLicensing - https://github.com/nicolonsky/AzureADLicensing
#>

#------------------------------------ Input parameters  ------------------------------------------------- #

#require AzureADLicensing
#require AzureADPreview
#require Az


$AADGroupName = "GLA-M365E5-PS2-Full"
$licencesSSKUName = "Microsoft 365 E5"

$AADcredentials = Get-Credential # Get Admin credentials for connections 

Import-Module AzureADPreview
Import-Module Az
Import-Module AzureADLicensing

Write-Host "Connecting to Tenant ..." -ForegroundColor Green

# Connect Azure AD

$AzureADsession = Get-AzureADCurrentSessionInfo

$AzureADsession = Get-AzContext
if (!($AzureADsession))
    {
        Connect-AzureAD -Credential $AADcredentials
    }
    else
    {

        Write-Host "Session exist for Azure AD module" -ForegroundColor Green

    }

# Connect Azure

$AZSession = Get-AzContext
if (!($AZSession))
    {
        Connect-AzureAD -Credential $AADcredentials
    }
    else
    {

        Write-Host "Session exist for AZ module" -ForegroundColor Green

    }

# Create New Security Group



$AADGroup = Get-AzureADGroup -SearchString $AADGroupName

if (([string]::IsNullOrEmpty($AADGroup))) # check that group exist
{

    Write-Host "Creating Azure AD group for licence base" -ForegroundColor Green
    
    $AADGroup = New-AzureADGroup -DisplayName $AADGroupName -Description "Group for license assignment" -SecurityEnabled $true -MailEnabled $false -MailNickName "NotSet"
    $AADGroupId = $AADGroup.ObjectId 

}
else
{

    Write-Host "Azure AD [$($AADGroup.DisplayName)] group for licence base alredy exist" -ForegroundColor Yellow

}


# Get SKU licences by Name

Write-Host "Get licence inforation" -ForegroundColor Green

$m365Sku= Get-AADLicenseSku | Where-Object {$_.name -match $licencesSSKUName}
$m365SkuID = $m365Sku.accountSkuId

# Assign M365 Full license to group created

Write-Host "Group License Assignment : $($AADGroup.DisplayName)" -ForegroundColor Green

Add-AADGroupLicenseAssignment -groupId $AADGroupId -accountSkuId $m365SkuID

# Verify license assignment

Get-AADGroupLicenseAssignment -groupId $AADGroupId