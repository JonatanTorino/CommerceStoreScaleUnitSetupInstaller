# Requires -RunAsAdministrator

param (
    [Parameter(Mandatory = $true)]
    [string]
    [ValidateNotNullOrEmpty()]$InstallersFoldersPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet('install', 'uninstall')]
    [ValidateNotNullOrEmpty()]$InstallOrUninstall
)

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

if(Test-Path $InstallersFoldersPath){
    C:\Windows\System32\inetsrv\appcmd stop apppool /apppool.name:RssuCore
    C:\Windows\System32\inetsrv\appcmd stop apppool /apppool.name:RetailServer

    Get-ChildItem -Path $InstallersFoldersPath -Filter *.exe | ForEach-Object {
        Write-Host
        Write-Host
        Write-Host -ForegroundColor Green $_.name "|" $InstallOrUninstall
        Start-Process -NoNewWindow -Wait $_.Fullname -ArgumentList $InstallOrUninstall
    }
    Write-Host 
    Write-Host 
    C:\Windows\System32\inetsrv\appcmd stop apppool /apppool.name:RssuCore
    C:\Windows\System32\inetsrv\appcmd start apppool /apppool.name:RetailServer
    Write-Host 
    Write-Host 
}
else{
    Write-Host -ForegroundColor Red  "Path is invalid"
}

$elapsedSecods = $stopwatch.Elapsed
Write-Host -ForegroundColor Green 'Total elapsed time: '
$elapsedSecods
$stopwatch.Stop()