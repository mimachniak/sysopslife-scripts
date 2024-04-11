#Requires –Modules Az.Sql

<#  
.SYNOPSIS  
    Script backup database to storage account and remove
.DESCRIPTION  
    Script will backup existind database to .bacpac on storage account,
    old databse will be removed.
    
.NOTES  
    File Name  : \Azure-azSQL-Backup-parm.ps1
    Author     : Michal Machniak  
    Requires   : PowerShell V5.1
.LINK
    Links for manula call

    .\\Azure-azSQL-Backup-parm.ps1 -azSqlResourceGroupName DEV-SQL `
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

    # example data: ST: devmmsql90905, container: azbackup, sql server: dev-mmsql90905, admin: sa.local

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

    [Parameter(Mandatory=$true,HelpMessage="Please enter the SQL sysadmin username")]
    [String]$azSqlAdministratorLogin,

    [Parameter(Mandatory=$true,HelpMessage="Please enter the SQL sysadmin username password")]
    [String]$azSqlAdminPassword


  )

## Storage Accunt ##

$storageBackupUrlContainer = "https://$storageAccount.blob.core.windows.net/$storageBlobContainer/"

## Backup files naming ##

$bacpacFilename = $azSqlServerName + '-' + $azSqlDatabaseName + '-' +(Get-Date).ToString("yyyyMMddTHHmmss") + ".bacpac"
$bacpacUri = $storageBackupUrlContainer + $bacpacFilename

## Check database exist ##

$azSqlDatabaseStatus = Get-AzSqlDatabase -ResourceGroupName $azSqlResourceGroupName `
    -ServerName $azSqlServerName `
    -DatabaseName $azSqlDatabaseName `
    -ErrorAction SilentlyContinue `
    -WarningAction SilentlyContinue

if (!($azSqlDatabaseStatus))
    {

        Write-Host "DataBase: [$azSqlDatabaseName] don't exist on SQL server: [$azSqlServerName]"

    }
    else
    {
        $exportSqlRequest = New-AzSqlDatabaseExport -ResourceGroupName $azSqlResourceGroupName `
            -ServerName $azSqlServerName `
            -DatabaseName $azSqlDatabaseName `
            -StorageKeyType StorageAccessKey `
            -StorageKey $(Get-AzStorageAccountKey -ResourceGroupName $azStorageAccResourceGroupName -StorageAccountName $storageNameAccount).Value[0] `
            -StorageUri $bacpacUri `
            -AdministratorLogin $azSqlAdministratorLogin `
            -AdministratorLoginPassword (ConvertTo-SecureString -String $azSqlAdminPassword -AsPlainText -Force)


        ## Status veryfication

        $exportSqlstatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $exportSqlRequest.OperationStatusLink

            Write-Host  "Status of export: " $exportSqlstatus.Status ", status:" $exportSqlstatus.StatusMessage

        [Console]::Write("Exporting [$azSqlDatabaseName]")
            while ($exportSqlstatus.Status -eq "InProgress")
            {
                Start-Sleep -s 10
                $exportSqlstatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $exportSqlRequest.OperationStatusLink
                [Console]::Write(".")
            }
            [Console]::WriteLine("Finished exporting [$azSqlDatabaseName] to file [$bacpacFilename]")
            $exportSqlstatus

         # Removeing old Database

        [Console]::Write("Removeing [$azSqlDatabaseName] form file [$bacpacFilename]")

        $removeRequest = Remove-AzSqlDatabase -ResourceGroupName $azSqlResourceGroupName `
            -ServerName $azSqlServerName `
            -DatabaseName $azSqlDatabaseName

        $removeRequest
    }