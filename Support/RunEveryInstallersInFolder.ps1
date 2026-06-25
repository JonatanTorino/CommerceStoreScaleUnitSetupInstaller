#Requires -Version 5.0
param (
    [Parameter(Mandatory = $true)]
    [string]
    [ValidateNotNullOrEmpty()]$InstallersFoldersPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet('install', 'uninstall')]
    [ValidateNotNullOrEmpty()]$InstallOrUninstall
)

. "$PSScriptRoot\SupportFunctions.ps1"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

if(Test-Path $InstallersFoldersPath){
    Stop-WebAppPoolForce -Name RssuCore
    Stop-WebAppPoolForce -Name RetailServer

    try {
        # Listas para almacenar los resultados
        $filesCompletedSuccessfully = @()
        $filesCompletedWithError = @()

        Get-ChildItem -Path $InstallersFoldersPath -Filter *.exe | ForEach-Object {
            Invoke-InstallerWithTracking -InstallerPath $_.FullName -Action $InstallOrUninstall `
                -CompletedSuccessfully ([ref]$filesCompletedSuccessfully) `
                -CompletedWithError ([ref]$filesCompletedWithError)
        }

        Show-InstallerSummary -CompletedSuccessfully $filesCompletedSuccessfully -CompletedWithError $filesCompletedWithError
    } finally {
        Write-Host
        Write-Host
        Start-WebAppPool -Name RssuCore
        Start-WebAppPool -Name RetailServer
        Write-Host
        Write-Host
    }
}
else{
    Write-Host -ForegroundColor Red  "Path is invalid"
}

$elapsedSecods = $stopwatch.Elapsed
Write-Host -ForegroundColor Green 'Total elapsed time: '
$elapsedSecods
$stopwatch.Stop()