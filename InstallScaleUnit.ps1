#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    [ValidateNotNullOrEmpty()]$jsonFile
)
choco install powershell-core -y

.\CheckJsonFile.ps1 $jsonFile
# .\CheckD365foConfigDependency.ps1 [Discontinuado]
.\InsertCmmSDKAzureActiveClientId.ps1 $jsonFile
.\CheckRegeditEntriesDependency.ps1
# .\CheckNetCoreBundleDependency.ps1 [Discontinuado]

    #Programa y versión concreta a buscar
    # $HostingBudle = "Microsoft ASP.NET Core 6.0.6 Hosting Bundle Options"
    $HostingBudle = "Microsoft ASP.NET Core 6.0.21 Hosting Bundle Options"
    # $url = "https://download.visualstudio.microsoft.com/download/pr/0d000d1b-89a4-4593-9708-eb5177777c64/cfb3d74447ac78defb1b66fd9b3f38e0/dotnet-hosting-6.0.6-win.exe"
    $url = "https://download.visualstudio.microsoft.com/download/pr/b50f2f63-23ed-4c96-9b38-71d319107d1b/26f8c79415eccaef1f2e0614e10cd701/dotnet-hosting-6.0.21-win.exe"
.\CheckAndDownload.ps1 $HostingBudle $url 

Write-Host 
Write-Host "========================================"
Write-Host "              InstallScaleUnit          "
Write-Host "========================================"
Write-Host 

$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

$ScaleUnitSetupPath=$json.ScaleUnitSetupPath
$HttpPort=$json.HttpPort
$CertStore="store:///My/LocalMachine?FindByThumbprint="
$Thumbprint=$json.Thumbprint
$SslCertFullPath=$CertStore+$Thumbprint
$RetailServerAadClientId=$json.RetailServerAadClientId
$RetailServerAadResourceId=$json.RetailServerAadResourceId
$CposAadClientId=$json.CposAadClientId
$AsyncClientAadClientId=$json.AsyncClientAadClientId
$config=$json.ChannelConfig
$IntervalAsyncClient=$json.IntervalAsyncClient

#Los parametros -Wait -PassThru son para el flujo del script
$process = Start-Process -FilePath $ScaleUnitSetupPath -Wait -PassThru -NoNewWindow -ArgumentList "install --TrustSqlServerCertificate --port $HttpPort --SslCertFullPath $SslCertFullPath --AsyncClientCertFullPath $SslCertFullPath --RetailServerCertFullPath $SslCertFullPath --RetailServerAadClientId $RetailServerAadClientId --RetailServerAadResourceId $RetailServerAadResourceId --CposAadClientId $CposAadClientId --AsyncClientAadClientId $AsyncClientAadClientId --config $config --SkipScaleUnitHealthCheck"
$process.WaitForExit()
if ($process.ExitCode -eq 0)
{
    .\ChangePosConfig.ps1 $json.RetailServerURL #La instalacion del RSSU posee una URL local, con este ps1 se cambia por la URL pública
    .\ChangeAsyncInterval.ps1 $IntervalAsyncClient
    .\ChangeIISWebSitesPath.ps1
    .\ChangeDefaultTimeout.Pos.Framework.js.ps1
    .\AddHealthCheckAndEnableSwaggerSetting.ps1
}
