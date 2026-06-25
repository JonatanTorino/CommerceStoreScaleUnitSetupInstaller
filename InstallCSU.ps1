#Requires -Version 5.0
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [string]$jsonFile
    ,
    [switch]$skipHostingBudle = $false
    ,
    [switch]$skipCheckGitRepoUpdated = $false
)

$logFile = Join-Path $PSScriptRoot "Install_$(hostname)_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logLine -Encoding UTF8
    Write-Host $Message -ForegroundColor $Color
}

. .\Support\SupportFunctions.ps1

if (!$skipCheckGitRepoUpdated) {
    .\Support\CheckGitRepoUpdated.ps1 . # el . representa el directorio actual
}

$jsonFile = GetJsonConfig -jsonFile $jsonFile -Suffix "CSU"

if ([string]::IsNullOrEmpty($jsonFile)) {
    throw [System.ArgumentNullException] "jsonFile" 
}

.\PreInstall\CSUCheckJsonFile.ps1 $jsonFile
.\PreInstall\CheckRegeditEntriesDependency.ps1
.\PreInstall\InsertApplicationInsightConfigInAxDB.ps1 $jsonFile
.\PreInstall\InsertCmmSDKDataInAxDB.ps1 $jsonFile
.\PreInstall\ReplaceXmlAppInsightsInstrumentationKey.ps1 $jsonFile 

if ($skipHostingBudle -eq $false) {
    winget install Microsoft.DotNet.HostingBundle.8
}

PrintFileName $MyInvocation.MyCommand.Name

$csu = . Get-CSUParameters $jsonFile 

if (Test-Path -Path $csu.SetupPath -PathType Leaf) {
    # Quitar la marca "unblock" del archivo descargado
    Unblock-File -Path $csu.SetupPath

    $RetailServerAadResourceId = "api://" + $csu.RetailServerAadClientId
    
    # # Construye el comando usando las variables
    $command = "$($csu.SetupPath) install"`
        + " --Config `"$($csu.ChannelConfig)`""`
        + " --port " + $csu.HttpPort`
        + " --SslCertThumbprint " + $csu.Thumbprint`
        + " --AsyncClientCertThumbprint " + $csu.Thumbprint`
        + " --RetailServerCertThumbprint " + $csu.Thumbprint`
        + " --RetailServerAadResourceId $RetailServerAadResourceId"`
        + " --RetailServerAadClientId " + $csu.RetailServerAadClientId`
        + " --CposAadClientId " + $csu.CposAadClientId`
        + " --AsyncClientAadClientId " + $csu.AsyncClientAadClientId`
        + " --TrustSqlServerCertificate" `
        + " --SkipScaleUnitHealthCheck" `
    # Ej de como usar condicionales para concatenar parámetros
        # + $(if ($skipOPOSCheck) { " --skipOPOSCheck"} )`

    # Ejecuta el comando
    Write-Log $command
    Invoke-Expression $command
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        .\PostInstall\AddHealthCheckAndEnableSwaggerSetting.ps1
        .\PostInstall\ChangeAsyncInterval.ps1 $csu.IntervalAsyncClient
        .\PostInstall\ChangeDefaultTimeout.Pos.Framework.js.ps1
        .\PostInstall\ChangePosConfig.ps1 $csu.RetailServerURL #La instalacion del RSSU posee una URL local, con este ps1 se cambia por la URL pública
        .\PostInstall\SetupIISWebSiteCSU.ps1 $csu.RetailServerURL
    }
}
else {
    Write-Log "ARCHIVO INSTALADOR NO ENCONTRADO. Ruta buscada: '$($csu.SetupPath)'. Verifique la propiedad CSUSetupPath en el archivo de configuración JSON." "Red"
}
