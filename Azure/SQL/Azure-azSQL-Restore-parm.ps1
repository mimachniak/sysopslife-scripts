#Requires –Modules Az.Sql

<#  
.SYNOPSIS  
    Script restore database from .bacpac file stored on storage account
.DESCRIPTION  
    Script will list all .bacpac on storage account,
    get last creted files by date and restore to database.
    
.NOTES  
    File Name  : Azure-azSQL-Restore-parm.ps1
    Author     : Michal Machniak  
    Requires   : PowerShell V5.1
.LINK
    Links for manula call

    .\Azure-azSQL-Restore-parm.ps1 -azSqlResourceGroupName DEV-SQL `
    -azStorageAccResourceGroupName DEV-SQL `
    -storageNameAccount devmmsql90905 `
    -storageBlobContainer azbackup `
    -azSqlServerName dev-mmsql90905 `
    -azSqlDatabaseName mmsql90905 `
    -azSqlAdministratorLogin sa.local

#>
[CmdletBinding()]
param (

    # variables define one or more parameters
    # this is a comma-separated list!

    [Parameter(Mandatory=$true,HelpMessage="Resource group name with Azure SQL")]
    [String]$azSqlResourceGroupName,

    [Parameter(Mandatory=$true,HelpMessage="Resource group name with Storage Account for backup files")]
    [String]$azStorageAccResourceGroupName,

    [Parameter(Mandatory=$true,HelpMessage="Storage Account")]  
    [String]$storageNameAccount,

    [Parameter(Mandatory=$true,HelpMessage="Storage Account container name for backup files")]
    [String]$storageBlobContainer,

    [Parameter(Mandatory=$true,HelpMessage="Azure SQL server name")]
    [String]$azSqlServerName,

    [Parameter(Mandatory=$false,HelpMessage="Azure SQL Database name")]
    [String]$azSqlDatabaseName = "dev-mmsample",

    [Parameter(Mandatory=$false,HelpMessage="Days that need to be check for backup files creation")]
    [String]$azSqlDaysRestore="-1",

    [Parameter(Mandatory=$true,HelpMessage="Please enter the SQL sysadmin username")]
    [String]$azSqlAdministratorLogin,

    [Parameter(Mandatory=$true,HelpMessage="Please enter the SQL sysadmin username password")]
    [String]$azSqlAdminPassword


  )

## SQL Server ##

if ($azSqlDatabaseName -eq $null)
{

    Write-Host "SQL server DB name is empty, random name will be generated"
    $azSqlDatabaseName = "dbrandom"+(Get-Random)
    Write-Host "SQL server DB random name: [$azSqlDatabaseName]"

}

# Create a blank database with an S0 performance level

New-AzSqlDatabase  -ResourceGroupName $azSqlResourceGroupName `
    -ServerName $azSqlServerName `
    -DatabaseName $azSqlDatabaseName `
    -Edition Standard `
    -RequestedServiceObjectiveName "S0" 

Write-Host "Empty database was created [$azSqlDatabaseName] on SQL Server [$azSqlServerName]"

Start-Sleep -second 10


# Get backup files with data

$bacpacFile = Get-AzStorageAccount -ResourceGroupName $azSqlResourceGroupName -Name $storageNameAccount | `
    Get-AzStorageContainer | Get-AzStorageBlob -Container $storageBlobContainer | `
    Where-Object {$_.LastModified.Date -eq (((Get-Date).AddDays($azSqlDaysRestore)).Date)} `
    | Sort-Object -Property LastModified -Descending `
    | Select-Object -First 1

    if ($bacpacFile -eq $null)
    {

        $bacpacFile = Get-AzStorageAccount -ResourceGroupName $azSqlResourceGroupName -Name $storageNameAccount | `
            Get-AzStorageContainer | Get-AzStorageBlob -Container $storageBlobContainer | `
            Sort-Object LastModified -Descending | `
            Select-Object -First 1

        $bacpacFilename = $bacpacFile.Name

        Write-Host "Use last created backup file: [$bacpacFilename] that was modyfied: " $bacpacFile.LastModified

    }
    else {


        $bacpacFilename = $bacpacFile.Name

        Write-Host "Use file [$bacpacFilename] created in days: [$azSqlDaysRestore]"
    }

Write-Host "File for import [$bacpacFilename] form storage account [$storageNameAccount]"

# Import bacpac to database

$importRequest = New-AzSqlDatabaseImport -ResourceGroupName $azSqlResourceGroupName `
    -ServerName $azSqlServerName `
    -DatabaseName $azSqlDatabaseName `
    -DatabaseMaxSizeBytes "262144000" `
    -StorageKeyType "StorageAccessKey" `
    -StorageKey $(Get-AzStorageAccountKey -ResourceGroupName $azStorageAccResourceGroupName -StorageAccountName $storageNameAccount).Value[0] `
    -StorageUri "https://$storageNameAccount.blob.core.windows.net/$storageBlobContainer/$bacpacFilename" `
    -Edition "Standard" `
    -ServiceObjectiveName "S0" `
    -AdministratorLogin "$azSqlAdministratorLogin" `
    -AdministratorLoginPassword $(ConvertTo-SecureString -String $azSqlAdminPassword -AsPlainText -Force)


# Check import status and wait for the import to complete

$importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink

[Console]::Write("Importing [$azSqlDatabaseName] form file [$bacpacFilename]")
    while ($importStatus.Status -eq "InProgress")
    {
        $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
        [Console]::Write(".")
        Start-Sleep -s 10
    }
[Console]::WriteLine("Finished: Importing [$azSqlDatabaseName] form file [$bacpacFilename]")
$importStatus