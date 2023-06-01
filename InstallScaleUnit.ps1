#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    [ValidateNotNullOrEmpty()]$jsonFile
)

.\CheckJsonFile.ps1 $jsonFile
.\InsertCmmSDKAzureActiveClientId.ps1 $jsonFile
.\CheckRegeditEntriesDependency.ps1
.\CheckNetCoreBundleDependency.ps1

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
}
