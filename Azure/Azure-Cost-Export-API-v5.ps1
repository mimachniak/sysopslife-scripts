## https://stackoverflow.com/questions/34353225/make-parameter-mandatory-based-on-switch-powershell


# Parameter
[CmdletBinding(DefaultParameterSetName='DefaultSettings')]
param(
    [Parameter(
      Position = 0
    )]
    [bool]$GenerateExcelFile = $true,
    [Parameter(
      Position = 1
    )]
    [bool]$GenerateHtmlFile = $false,
    [Parameter(
    )]
    [string]$reportFilePath,
    [Parameter(
      HelpMessage = "Date in format yyyy-MM-dd"
      )]
    [string]$startDate = (Get-Date).AddMonths(-1).ToString("yyyy-MM-01"),
    [Parameter(HelpMessage = "Date in format yyyy-MM-dd")]
    [string]$endDate = (Get-Date).AddDays(-1 * (Get-Date).Day).ToString("yyyy-MM-dd"),
    [Parameter(
      )]
    [bool]$interactiveLogon = $true,

    [Parameter(Mandatory=$True, ParameterSetName='SendMail')]
    [switch]$sendMail,
    [Parameter(Mandatory=$false, ParameterSetName='SendMail')]
    [String]$EmailFrom = "",
    [Parameter(Mandatory=$false, ParameterSetName='SendMail')]
    [String]$EmailTo = "",
    [Parameter(Mandatory=$false, ParameterSetName='SendMail')]
    [String]$SMTPServer = "",
    [Parameter(Mandatory=$false, ParameterSetName='SendMail')]
    [string]$smtpPort = 587,
    [Parameter(Mandatory=$false, ParameterSetName='SendMail')]
    [string]$Subject = "Monthly reports Azure Cost for date time: $startDate to $endDate",
    [Parameter(Mandatory=$false, ParameterSetName='SendMail')]
    [string]$Body = @"
    Hello,<br />Here are the monthly reports for Azure Cost for date time: $startDate to $endDate.<br /><br />`
</a>
"@
)


#[bool]$GenerateExcelFile = $true
#[bool]$GenerateHtmlFile = $false


# Step: File name and path generation

if ($reportFilePath -eq '') {

    $reportFilePath = $PSScriptRoot

  } else {
    $reportFilePath
}

Write-Host "Path: $reportFilePath" -ForegroundColor Red



# Setup report data

$dateString = (Get-Date).ToString('yyyyMMdd-mmss')
$fileNameExcel = '030 - '+$((Get-Date).ToString('yyyy_MM'))+'- Azure-Cost-'+$dateString+'.xlsx'
$reportFileExcel = $reportFilePath+$fileNameExcel

$fileNameHtml = 'Azure-Cost-'+$dateString+'.html'
$reportFileHtml = $reportFilePath+$fileNameHtml


# Connect to Azure

if ($interactiveLogon) {

  $AzureContext = Get-AzContext
  if($null -eq $AzureContext.Account)
  {
      Write-Host "Connect to Azure session"
      Connect-AzAccount
  }
} else {

  Disable-AzContextAutosave -Scope Process

  $AzureContext = (Connect-AzAccount -Identity).context
  Write-Output -InputObject $AzureContext

  $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
  Write-Output -InputObject $AzureContext
}

# Get Token of currecnt session

$token = (Get-AzAccessToken).Token
$authHeader = @{  
  'Content-Type'='application/json'  
  'Authorization'="Bearer $token" 
} 

$list_subscriptions = Get-AzSubscription | Select-Object -ExpandProperty SubscriptionId
$cost_report_full = @()
$list_az_subscription_tags = @()

foreach ($subscription in $list_subscriptions) {
  $az_subscription_tags = (Get-AzTag).Name

  $list_az_subscription_tags += $az_subscription_tags
}


$body_cost = @"
{
  "type": "ActualCost",
  "dataSet": {
    "granularity": "None",
    "aggregation": {
      "totalCost": {
        "name": "Cost",
        "function": "Sum"
      },
      "totalCostUSD": {
        "name": "CostUSD",
        "function": "Sum"
      }
    },
    "sorting": [
      {
        "direction": "descending",
        "name": "Cost"
      }
    ],
    "include": [
      "Tags"
    ],
    "grouping": [
      {
        "type": "Dimension",
        "name": "ResourceId"
      },
      {
        "type":"Dimension",
        "name":"ResourceLocation"
      },
      {
        "type":"Dimension",
        "name":"SubscriptionName"
      }
    ]
  },
  "timeframe": "Custom",
  "timePeriod": {
    "from":"$($startDate)",
    "to":"$($endDate)"
  }
}
"@

foreach ($subscription in $list_subscriptions) {

Write-Host "Generate data for subscription: $subscription"

$request_cost = Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$($subscription)/providers/Microsoft.CostManagement/query?api-version=2021-10-01" -ContentType "application/json" -Method "Post" -Body $body_cost -Headers $authHeader

$cost_report = @() # Report Declaration

foreach ($row in $request_cost.properties.rows) {
          
          [array]$tags = $row[5] | Sort-Object
          $tags_string = $tags -join ";"
          $ResourceName = ($row[2].Split('/'))[8]

          #Write-Host "Add data of row to PS object"
          $row_in_report = New-Object PSObject -Property @{ 

            CostEUR  = $row[0]
            CostUSD  = $row[1]
            ResourceId = $row[2]
            ResourceLocation = $row[3]
            SubscriptionName = $row[4]
            Tags = $tags_string
            Currency = $row[6]
            ResourceName = $ResourceName
            ResourceType = ($row[2].Split('/'))[7]
            ResourceGroupName = ($row[2].Split('/'))[4]
        
        }
        
        foreach ($az_tag in $list_az_subscription_tags) {

          $row_in_report | Add-Member -MemberType NoteProperty -Name $az_tag -Value 'null' -Force

        }

        #Write-Host "Tags convertion for: $ResourceName" -ForegroundColor Red
        foreach ($tag in $tags)
        {

          $tags_split = $tag -split ":"
          [string]$tags_string_name = ($tags_split[0]).ToString() -replace('"','')
          [string]$tags_string_value = ($tags_split[1]).ToString() -replace('"','')
          
          #$row_in_report | Add-Member -NotePropertyName $tags_string_name -NotePropertyValue $tags_string_value -PassThru
          $row_in_report | Add-Member -MemberType NoteProperty -Name $tags_string_name -Value $tags_string_value -Force
<#
          if (-not ($row_in_report | Get-Member -Name $tags_string_name)) {
            Add-Member `
              -InputObject $row_in_report `
              -NotePropertyName $tags_string_name `
              -NotePropertyValue $tags_string_value
             }
#>
        }
        
    ### Add to arraya ##
    $cost_report  += $row_in_report  # Append the object to the array / merge row to PSCustomObject
    } # and of loop for each row

    $cost_report_full +=$cost_report #one report

    Write-Host "Start wait time ...."
    Start-Sleep -Seconds 60
} #end of each subscription

if ($GenerateExcelFile) {

    Write-Host "Save raport in Location: $reportFileExcel "

    $excel_report = $cost_report_full | Export-Excel -Path $reportFileExcel -WorksheetName "AzureCost" -TableName "AzureCost" -StartRow 4 -PassThru

    $wsXls = $excel_report.AzureCost

    $wsXls.Cells["A1"].Value = "Date of Generation: "
    $wsXls.Cells["B1"].Value = (Get-Date).ToString("yyyyMMdd")
    $wsXls.Cells["C1"].Value = "Monthy of the report::"
    $wsXls.Cells["D1"].Value = ((Get-Date).AddMonths(-1)).ToString("MM")
    $wsXls.Cells["C2"].Value = "Tenant Name:"
    $wsXls.Cells["D2"].Value = (Get-AzTenant).Name

    Set-ExcelRange -Worksheet $wsXls -Range ("A1") -Bold
    Set-ExcelRange -Worksheet $wsXls -Range ("C1") -Bold
    Set-ExcelRange -Worksheet $wsXls -Range ("C2") -Bold

    $wsXls.Cells.AutoFitColumns()

    $excel_report.Save()
    $excel_report.Dispose()
} else {

  Write-Host "No file Generated object"
  #$cost_report_full

}

if ($GenerateHtmlFile) {
  Write-Host "Save raport in Location: $reportFileHtml "
  ConvertTo-Html -InputObject $cost_report_full | Out-File -FilePath $reportFileHtml
} else {

  Write-Host "No file generated html"
  #$cost_report_full

}

# Send e-mail

if ($sendMail) {

  if ($interactiveLogon) {

    $SMTPCredential = Get-Credential

  } else {

    $SMTPCredential = Get-AutomationPSCredential -Name 'ITNoReply-MailJet' 

  }

  $encodingMail = [System.Text.Encoding]::UTF8
  [array]$attachments = $reportFileExcel

  try {
      Send-MailMessage -smtpServer $SMTPServer -From $EmailFrom -Credential $SMTPCredential -UseSsl -Port 587 -to $EmailTo -subject $Subject -BodyAsHtml $Body -Encoding $encodingMail -Attachments $attachments

  }
  catch {   
      $ErrorMessage = $Error[0].Exception.Message
      Write-Output "Error: $ErrorMessage"
  }
}
