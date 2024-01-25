# #Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [string]$jsonFile
    ,
    [switch]$skipHostingBudle = $false
    ,
    [switch]$skipCheckGitRepoUpdated = $false
)

if (!$skipCheckGitRepoUpdated) {
    .\CheckGitRepoUpdated.ps1 . # el . representa el directorio actual
}

$GetJsonConfigFile = ".\GetJsonConfigFile.ps1"
$jsonFile = & $GetJsonConfigFile -JsonFile $jsonFile

if ([string]::IsNullOrEmpty($jsonFile)) {
    throw [System.ArgumentNullException] "jsonFile" 
}

Write-Host 
Write-Host "========================================"
Write-Host "     Update Certificate for CSU          "
Write-Host "========================================"
Write-Host 

$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

$ScaleUnitSetupPath = $json.ScaleUnitSetupPath
if (Test-Path -Path $ScaleUnitSetupPath -PathType Leaf) {
    
    try {
        Stop-WebAppPool -Name 'RetailServer'
    } catch { }

    #Los parametros -Wait -PassThru son para el flujo del script
    #Los parametros -Wait -PassThru son para el flujo del script
    $process = Start-Process -FilePath $ScaleUnitSetupPath -Wait -PassThru -NoNewWindow -ArgumentList "updateCertificates --SslCertFullPath $SslCertFullPath --AsyncClientCertFullPath $SslCertFullPath  --RetailServerCertFullPath $SslCertFullPath"

    $process.WaitForExit()

    try {
        Start-WebAppPool -Name 'RetailServer'
    } catch { }
}
else {
    Write-Host -ForegroundColor Red "ARCHIVO INSTALADOR NO ENCONTRADO"
    Write-Host -ForegroundColor Red "   $ScaleUnitSetupPath"
}