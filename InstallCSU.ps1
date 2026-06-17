#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [string]$jsonFile
    ,
    [switch]$skipHostingBudle = $false
    ,
    [switch]$skipCheckGitRepoUpdated = $false
)

if ($PSVersionTable.PSVersion.Major -ge 6) {
    Write-Warning "Este script requiere Windows PowerShell 5.1 debido a dependencias con IIS y WebAdministration."
    Write-Warning "Re-ejecutando en Windows PowerShell 5.1..."
    
    $params = @()
    if ($jsonFile) { $params += "-jsonFile", $jsonFile }
    if ($skipHostingBudle) { $params += "-skipHostingBudle" }
    if ($skipCheckGitRepoUpdated) { $params += "-skipCheckGitRepoUpdated" }
    
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath $params
    exit $LASTEXITCODE
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
    #Programa y versión concreta a buscar
    Write-Host 
    Write-Host "========================================"
    Write-Host "    Microsoft ASP.NET Core 8 Hosting Bundle Options"
    Write-Host "========================================"
    Write-Host 
    winget install Microsoft.DotNet.HostingBundle.8 --silent
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
    write-host $command
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
    Write-Host -ForegroundColor Red "ARCHIVO INSTALADOR NO ENCONTRADO"
    Write-Host -ForegroundColor Red "   $($csu.SetupPath)"
    Write-Host -ForegroundColor Red "Revisar la configuración del json.CSUSetupPath que tenga la ruta completa al instalador"
}
