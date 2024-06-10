# #Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [string]$jsonFile
    ,
    [switch]$skipHostingBudle = $false
    ,
    [switch]$skipCheckGitRepoUpdated = $false
    ,
    [switch]$skipTelemetryCheck = $false
)

if (!$skipCheckGitRepoUpdated) {
    .\CheckGitRepoUpdated.ps1 . # el . representa el directorio actual
}

$GetJsonConfigFile = ".\GetJsonConfigFile.ps1"
$jsonFile = & $GetJsonConfigFile -JsonFile $jsonFile

if ([string]::IsNullOrEmpty($jsonFile)) {
    throw [System.ArgumentNullException] "jsonFile" 
}

.\ReplaceXmlAppInsightsInstrumentationKey.ps1 $jsonFile 
.\CheckJsonFile.ps1 $jsonFile
# [Discontinuado] .\CheckD365foConfigDependency.ps1 
.\InsertCmmSDKAzureActiveClientId.ps1 $jsonFile
.\SetApplicationInsightConfig.ps1 $jsonFile
.\CheckRegeditEntriesDependency.ps1
# [Discontinuado] .\CheckNetCoreBundleDependency.ps1

if ($skipHostingBudle -eq $false) {
    #Programa y versión concreta a buscar
    # $HostingBudle = "Microsoft ASP.NET Core 6.0.6 Hosting Bundle Options"
    # $url = "https://download.visualstudio.microsoft.com/download/pr/0d000d1b-89a4-4593-9708-eb5177777c64/cfb3d74447ac78defb1b66fd9b3f38e0/dotnet-hosting-6.0.6-win.exe"
    $HostingBudle = "Microsoft ASP.NET Core 6.0.21 Hosting Bundle Options"
    $url = "https://download.visualstudio.microsoft.com/download/pr/b50f2f63-23ed-4c96-9b38-71d319107d1b/26f8c79415eccaef1f2e0614e10cd701/dotnet-hosting-6.0.21-win.exe"
    # $HostingBudle = "Microsoft ASP.NET Core 6.0.26 Hosting Bundle Options"
    # $url = "https://download.visualstudio.microsoft.com/download/pr/16e13e4d-a240-4102-a460-3f4448afe1c3/3d832f15255d62bee8bc86fed40084ef/dotnet-hosting-6.0.26-win.exe"
    .\CheckAndDownload.ps1 $HostingBudle $url 
}

Write-Host 
Write-Host "========================================"
Write-Host "              InstallScaleUnit          "
Write-Host "========================================"
Write-Host 

$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

$ScaleUnitSetupPath = $json.ScaleUnitSetupPath
if (Test-Path -Path $ScaleUnitSetupPath -PathType Leaf) {
    # Quitar la marca "unblock" del archivo descargado
    Unblock-File -Path $ScaleUnitSetupPath

    $HttpPort = $json.HttpPort
    $CertStore = "store:///My/LocalMachine?FindByThumbprint="
    $Thumbprint = $json.Thumbprint
    $SslCertFullPath = $CertStore + $Thumbprint
    $RetailServerAadClientId = $json.RetailServerAadClientId
    $RetailServerAadResourceId = $json.RetailServerAadResourceId
    $CposAadClientId = $json.CposAadClientId
    $AsyncClientAadClientId = $json.AsyncClientAadClientId
    $config = $json.ChannelConfig
    $IntervalAsyncClient = $json.IntervalAsyncClient

    try {
        Stop-WebAppPool -Name 'RetailServer'
    }
    catch { }

    if ($skipTelemetryCheck) {
        $process = Start-Process -FilePath $ScaleUnitSetupPath -Wait -PassThru -NoNewWindow -ArgumentList "install --TrustSqlServerCertificate --port $HttpPort --SslCertFullPath $SslCertFullPath --AsyncClientCertFullPath $SslCertFullPath --RetailServerCertFullPath $SslCertFullPath --RetailServerAadClientId $RetailServerAadClientId --RetailServerAadResourceId $RetailServerAadResourceId --CposAadClientId $CposAadClientId --AsyncClientAadClientId $AsyncClientAadClientId --config $config --SkipScaleUnitHealthCheck --skipTelemetryCheck" 
    }
    else {
        #Los parametros -Wait -PassThru son para el flujo del script
        $process = Start-Process -FilePath $ScaleUnitSetupPath -Wait -PassThru -NoNewWindow -ArgumentList "install --TrustSqlServerCertificate --port $HttpPort --SslCertFullPath $SslCertFullPath --AsyncClientCertFullPath $SslCertFullPath --RetailServerCertFullPath $SslCertFullPath --RetailServerAadClientId $RetailServerAadClientId --RetailServerAadResourceId $RetailServerAadResourceId --CposAadClientId $CposAadClientId --AsyncClientAadClientId $AsyncClientAadClientId --config $config --SkipScaleUnitHealthCheck"    
    }

    $process.WaitForExit()
    if ($process.ExitCode -eq 0) {
        .\ChangePosConfig.ps1 $json.RetailServerURL #La instalacion del RSSU posee una URL local, con este ps1 se cambia por la URL pública
        .\ChangeAsyncInterval.ps1 $IntervalAsyncClient
        .\ChangeIISWebSitesPath.ps1
        .\ChangeDefaultTimeout.Pos.Framework.js.ps1
        .\AddHealthCheckAndEnableSwaggerSetting.ps1
    }

    try {
        Start-WebAppPool -Name 'RetailServer'
    }
    catch { }
} 
else {
    Write-Host -ForegroundColor Red "ARCHIVO INSTALADOR NO ENCONTRADO"
    Write-Host -ForegroundColor Red "   $ScaleUnitSetupPath"
}
