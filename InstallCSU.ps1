#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [string]$jsonFile
    ,
    [switch]$skipHostingBudle = $false
    ,
    [switch]$skipCheckGitRepoUpdated = $false
)

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
    # $HostingBudle = "Microsoft ASP.NET Core 6.0.35 Hosting Bundle Options"
    # $url = "https://download.visualstudio.microsoft.com/download/pr/59c72253-7750-4f34-8804-4fb326754c4f/b83a6a459d49b6127757b4f873ba459f/dotnet-hosting-6.0.35-win.exe"
    $HostingBudle = "Microsoft ASP.NET Core 8.0.11 Hosting Bundle Options"
    $url = "https://download.visualstudio.microsoft.com/download/pr/4956ec5e-8502-4454-8f28-40239428820f/e7181890eed8dfa11cefbf817c4e86b0/dotnet-hosting-8.0.11-win.exe"
    .\Support\CheckAndDownload.ps1 $HostingBudle $url 
}

PrintFileName $MyInvocation.MyCommand.Name

$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

$CSUSetupPath = $json.CSUSetupPath
if (Test-Path -Path $CSUSetupPath -PathType Leaf) {
    # Quitar la marca "unblock" del archivo descargado
    Unblock-File -Path $CSUSetupPath

    $config = $json.CSUChannelConfig
    $RetailServerAadResourceId = "api://" + $json.RetailServerAadClientId
    
    # # Construye el comando usando las variables
    $command = "$CSUSetupPath install"`
        + " --Config `"$config`""`
        + " --port " + $json.CSUHttpPort`
        + " --SslCertThumbprint " + $json.Thumbprint`
        + " --AsyncClientCertThumbprint " + $json.Thumbprint`
        + " --RetailServerCertThumbprint " + $json.Thumbprint`
        + " --RetailServerAadResourceId $RetailServerAadResourceId"`
        + " --RetailServerAadClientId " + $json.RetailServerAadClientId`
        + " --CposAadClientId " + $json.CposAadClientId`
        + " --AsyncClientAadClientId " + $json.AsyncClientAadClientId`
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
        .\PostInstall\ChangeAsyncInterval.ps1 $json.IntervalAsyncClient
        .\PostInstall\ChangeDefaultTimeout.Pos.Framework.js.ps1
        .\PostInstall\ChangePosConfig.ps1 $json.RetailServerURL #La instalacion del RSSU posee una URL local, con este ps1 se cambia por la URL pública
        .\PostInstall\SetupIISWebSiteCSU.ps1 $json.RetailServerURL
    }
}
else {
    Write-Host -ForegroundColor Red "ARCHIVO INSTALADOR NO ENCONTRADO"
    Write-Host -ForegroundColor Red "   $CSUSetupPath"
    Write-Host -ForegroundColor Red "Revisar la configuración del json.CSUSetupPath que tenga la ruta completa al instalador"
}
