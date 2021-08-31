﻿<#  
.SYNOPSIS  
    Script will download new Office templates each time it runs.
.DESCRIPTION  
    Script connects to remote azure storage account, and download new Office templates.
    Template are refresh each time script run and putted in dedicated folder.
 
    
.NOTES  
    File Name  : Intune-DocumentTemplateStorageAccount.ps1 
    Author     : Michal Machniak  
    Requires   : PowerShell V5.1
.LINK

    Github: https://github.com/mimachniak/sysopslife-scripts
    Site: https://sysopslife.sys4ops.pl/
    Modules links:
#>

#------------------------------------ Input parameters  ------------------------------------------------- #

$LogLocation = 'C:\Users\Public\Documents\' # Location of lgs generated by execution of the script
$LogFileName = 'OfficeTemplates.log' # log file name


Start-Transcript -Path  $LogLocation$LogFileName# Create log each run script

$storageAccountName = "dofficetemplate.blob.core.windows.net" # Azure Storage Acccount Url
$containerName = "office-template" # Azure storage account blob container with files
$TemplateFolderName = 'Office Templates' # Folder name on desktop when files willbe downloaded



    $MyDocumentsPath = [Environment]::GetFolderPath("MyDocuments") # Get default location of Documents
    $CustomTemplatesLocation = $MyDocumentsPath+"\"+$TemplateFolderName #Flder for custom templates

    if ((Test-Path $CustomTemplatesLocation) -eq $false)
        {
            New-Item -Path $MyDocumentsPath -Name $TemplateFolderName -ItemType "directory"
        }

        $CustomWordTemplatesLocation = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\Word\Options" -Name "PersonalTemplates"
        $CustomPowerPointTemplatesLocation = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\16.0\PowerPoint\Options" -Name "PersonalTemplates"

    if ($CustomWordTemplatesLocation -ne $null)
        {
            Write-Host "PersonalTemplates reg exist in HKCU:\SOFTWARE\Microsoft\Office\16.0\Word\Options"
        }
        else {

            New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Office\16.0\Word\Options -Name "PersonalTemplates" -Value $CustomTemplatesLocation -PropertyType ExpandString -Force # Setup custom temaplate folder for Word
        }


    if ($CustomPowerPointTemplatesLocation -ne $null)
        {
            Write-Host "PersonalTemplates reg exist in HKCU:\SOFTWARE\Microsoft\Office\16.0\PowerPoint\Options"
        }
        else {

            New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Office\16.0\PowerPoint\Options -Name "PersonalTemplates" -Value $CustomTemplatesLocation -PropertyType ExpandString -Force # Setup custom temaplate folder for PowerPoint
        }

write-host "https://$storageAccountName/$containerName/?comp=list" # URL with files

$xml = Invoke-WebRequest -Method Get -Uri "https://$storageAccountName/$containerName/?comp=list" -ContentType "application/xml" # Get All files in Blob Container without SAS toke
[xml] $i = $xml.Content -replace "ï»¿", ""
$ListBlobs = $i.EnumerationResults.Blobs.Blob

    foreach ($BlobFile in $ListBlobs)
    {

        $TemplatesLocation = $CustomTemplatesLocation+"\"+$BlobFile.Name

        Write-Host "Location of file [$TemplatesLocation]"

        $fileDownloadBlob = try {

                Invoke-WebRequest -Uri $BlobFile.Url -OutFile $TemplatesLocation

                Write-Host "File downloaded [$($BlobFile.Name)]"
            }
            catch [System.Net.WebException] {

                Write-Warning "Exception was caught: $($_.Exception.Message)"
    
            }
    }

Stop-Transcript # End logging