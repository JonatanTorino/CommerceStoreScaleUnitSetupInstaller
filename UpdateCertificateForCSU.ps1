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

$GetJsonConfigFile = ".\Support\GetJsonConfigFile.ps1"
$jsonFile = & $GetJsonConfigFile -JsonFile $jsonFile

if ([string]::IsNullOrEmpty($jsonFile)) {
    throw [System.ArgumentNullException] "jsonFile" 
}

.\PreInstall\InsertCmmSDKAzureActiveClientId.ps1 $jsonFile

CurrentFileName $MyInvocation.MyCommand.Name

$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

$CSUSetupPath = $json.CSUSetupPath
if (Test-Path -Path $CSUSetupPath -PathType Leaf) {

    # # Construye el comando usando las variables
    $command = "$CSUSetupPath updateCertificates"`
        + " --SslCertThumbprint " + $json.Thumbprint`
        + " --AsyncClientCertThumbprint " + $json.Thumbprint`
        + " --RetailServerCertThumbprint " + $json.Thumbprint`
    # Ej de como usar condicionales para concatenar parámetros
        # + $(if ($skipOPOSCheck) { " --skipOPOSCheck"} )`
        
    # Ejecuta el comando
    write-host $command
    Invoke-Expression $command
    # $exitCode = $LASTEXITCODE
}
else {
    Write-Host -ForegroundColor Red "ARCHIVO INSTALADOR NO ENCONTRADO"
    Write-Host -ForegroundColor Red "   $CSUSetupPath"
    Write-Host -ForegroundColor Red "Revisar la configuración del json.CSUSetupPath"
}
