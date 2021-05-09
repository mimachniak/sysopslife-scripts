<#  
.SYNOPSIS  
    Configure Windows Server for SQL Server installation.
.DESCRIPTION  
    Prepare all depends for SQL server installation on Windows Server.
    * Net
    * Firewall
    * PageIO file
  
.NOTES  
    File Name  : SQLServer-Windows-prep.ps1 
    Author     : Michal Machniak  
    Requires   : PowerShell V5.1
.LINK

    Github: https://github.com/mimachniak/sysopslife-scripts
    Site: https://sysopslife.sys4ops.pl/

#>

#------------------------------------ Input parameters  ------------------------------------------------- #


$Servers = Read-Host "Server FQDN or IP (multiple server separat ',')"
$Credentials = Get-Credential
### Set settings ###
$Session = New-PSSession -ComputerName $Servers -Credential $Credentials
Invoke-Command -Session $Session -ScriptBlock {
##### Michał Machniak ######
##### v 1.0 #####
#### Input #####
### Global vars ###
$IODriveRead = Read-Host "Enter PageIO driver letter (empty will use default where drive Lable is 'PageIO')"
    if ($IODriveRead -eq "")
    {
        $DriveLetrter = Get-Volume -FileSystemLabel 'PageIO'
        $IODrive = $DriveLetrter.DriveLetter

    }
    else
    {
        $IODrive = $IODriveRead
    }
$WinRepo = '\\{Server Name}\Repo' # Net 3.5.1 Libries 
#####
"Check dependencies .....NET Framework 3.5"
$Feature = Get-WindowsFeature -name *NET-Framework-Core*
if ($Feature.Installed -eq $true)
    {
        Write-Host ".NET Framework 3.5 is INSTALLED" -ForegroundColor Yellow

    }
    else
    {
        Write-Host "INSTALLING .NET Framework 3.5" -ForegroundColor Green
        #####
        if ((Test-Path $WinRepo) -eq $true )
        {
            Install-WindowsFeature Net-Framework-Core -source $WinRepo\Repo\dotnet35\sxs -ErrorAction Stop -Verbose
        }
        else 
        {
            Install-WindowsFeature Net-Framework-Core -ErrorAction Stop -Verbose
        }
        #####
        Write-Host ".NET Framework 3.5 was INSTALLED" -ForegroundColor Green
    }
    "Check dependencies .....Failover Cluster"
    $Feature = Get-WindowsFeature -name Failover-Clustering
    if ($Feature.Installed -eq $true)
        {
            Write-Host "Failover Clustering is INSTALLED" -ForegroundColor Yellow
    
        }
        else
        {
            Write-Host "INSTALLING Failover Clustering" -ForegroundColor Green
            #####
            Install-WindowsFeature Failover-Clustering -IncludeManagementTools -ErrorAction Stop -Verbose
            #####
            Write-Host "Failover Clustering was INSTALLED" -ForegroundColor Green
        }
        "Check dependencies .....Firewall"
        if ((Get-NetFirewallRule -DisplayName "SQL Server Browser (UDP-in)" -ErrorAction SilentlyContinue) -ne $null)
        {
        
            Write-Host "SQL Server Browser (UDP-in) EXIST" -ForegroundColor Yellow
        
        }
        else
        {
            Write-Host "Adding SQL Server Browser (UDP-in)" -ForegroundColor Green
            New-NetFirewallRule -DisplayName "SQL Server Browser (UDP-in)" -Direction Inbound -Action Allow -LocalPort 1434 -Protocol UDP -ErrorAction Stop
            Write-Host "ADDED SQL Server Browser (UDP-in)" -ForegroundColor Green
        
        }
        
        ###
        
        if ((Get-NetFirewallRule -DisplayName "SQL Server Data (TCP-in)" -ErrorAction SilentlyContinue) -ne $null)
        {
        
            Write-Host "SQL Server Data (TCP-in) EXIST" -ForegroundColor Yellow
        
        }
        else
        {
            Write-Host "Adding SQL Server Data (TCP-in)" -ForegroundColor Green
            New-NetFirewallRule -DisplayName "SQL Server Data (TCP-in)" -Direction Inbound -Action Allow -LocalPort 1433 -Protocol TCP -ErrorAction Stop
            Write-Host "ADDED SQL Server Data (TCP-in)" -ForegroundColor Green
        
        }
        
        ###
        
        if ((Get-NetFirewallRule -DisplayName "SQL Server Replication (TCP-in)" -ErrorAction SilentlyContinue) -ne $null)
        {
        
            Write-Host "SQL Server Replication (TCP-in)" -ForegroundColor Yellow
        
        }
        else
        {
            Write-Host "Adding SQL Server Replication (TCP-in)" -ForegroundColor Green
            New-NetFirewallRule -DisplayName "SQL Server Replication (TCP-in)" -Direction Inbound -Action Allow -LocalPort 5022 -Protocol TCP -ErrorAction Stop
            Write-Host "ADDED SQL Server Replication (TCP-in)" -ForegroundColor Green
        
        }
        ### Pagefile settings
        Write-Host "Change Virtual Memory file location (pagefile.sys)" -ForegroundColor Yellow
        if ($PageIODisk -eq $false)
        {

             Write-Warning "Disk $IODrive is not avlible"

        }
        else 
        {
            wmic.exe pagefileset create name="$IODrive"+":\pagefile.sys" 
            Restart-Computer -Force
        } # End page IO
} # End of script block