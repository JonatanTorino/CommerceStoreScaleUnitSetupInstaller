#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    [ValidateNotNullOrEmpty()]$jsonFile
)

.\CheckD365foConfigDependency.ps1 $jsonFile
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

Start-Process -FilePath $ScaleUnitSetupPath -Wait -NoNewWindow -ArgumentList "install --TrustSqlServerCertificate --port $HttpPort --SslCertFullPath $SslCertFullPath --AsyncClientCertFullPath $SslCertFullPath --RetailServerCertFullPath $SslCertFullPath --RetailServerAadClientId $RetailServerAadClientId --RetailServerAadResourceId $RetailServerAadResourceId --CposAadClientId $CposAadClientId --AsyncClientAadClientId $AsyncClientAadClientId --config $config --SkipScaleUnitHealthCheck"

.\ChangePosConfig.ps1 $json.RetailServerURL #La instalacion del RSSU posee una URL local, con este ps1 se cambia por la URL pública
.\ChangeAsyncInterval.ps1 00:01:00
.\ChangeIISWebSitesPath.ps1
