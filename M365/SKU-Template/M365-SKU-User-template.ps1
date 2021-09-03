
# Get disbaled plans temaplete

# Prmeterers
# URL or Path
# UPN
#Param(
#  [ValidateSet(“Tom”,”Dick”,”Jane”)]
#  [String]
#  $Name
# List of SKU
# User not add go for all accounts

$disabledPlansTemplatePath = https://github.com/mimachniak/sysopslife-scripts/blob/master/M365/SKU-Template/m365.disabledPlans.sku.json
$disabledPlansTemplatePath 

$disabledPlans = Get-Content -Path C:\Git\Private\sysopslife-scripts\M365\SKU-Template\m365.disabledPlans.sku.json | ConvertFrom-Json

$Credential = Get-Credential

foreach ($i in $Plans.disabledPlans)
{

    Write-Host "This plan will be disbaled" $i

}

### Office 365 settings ###

  Connect-MsolService -Credential $Credential

  $SkuID = (Get-MsolAccountSku | Where-Object {$_.AccountSkuID -like '*ENTERPRISEPACK*'}).AccountSkuID
  #(Get-MsolAccountSku | Where-Object {$_.AccountSkuID -like '*ENTERPRIS*'}).ServiceStatus
  $Plans= @()
  $Plans +="YAMMER_ENTERPRISE"
  #$Plans +="RMS_S_ENTERPRISE "
  $Plans +="INTUNE_O365"
  $Plans +="FLOW_O365_P2"
  $Plans +="POWERAPPS_O365_P2"


### Setup licences for user in Office 365 ###

  Write-Host "Setting UP licences for new users" -ForegroundColor Green
  $disabledPlans = New-MsolLicenseOptions -AccountSkuId $SkuID -DisabledPlans $Plans
  Get-MsolUser -UserPrincipalName $PrincipalName| Set-MsolUser -UsageLocation "PL"
  Get-MsolUser -UserPrincipalName $PrincipalName | Set-MsolUserLicense -AddLicenses $SkuID -LicenseOptions $disabledPlans
  # Need EMS enabled

  Write-Host "Waiting for catalog synchronization" -ForegroundColor Yellow

  Start-Sleep -Seconds 120 # Wait for Provisioning