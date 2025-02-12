#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [string]$jsonFile
    ,
    [switch]$skipHostingBudle = $false
    ,
    [switch]$skipCheckGitRepoUpdated = $false
    ,
    [switch]$skipOPOSCheck = $false
)

if (!$skipCheckGitRepoUpdated) {
    .\CheckGitRepoUpdated.ps1 . # el . representa el directorio actual
}

$GetJsonConfigFile = ".\GetJsonConfigFile.ps1"
$jsonFile = & $GetJsonConfigFile -JsonFile $jsonFile

if ([string]::IsNullOrEmpty($jsonFile)) {
    throw [System.ArgumentNullException] "jsonFile" 
}

# .\CheckHwsSetting.ps1 $jsonFile
.\PreInstall\CheckRegeditEntriesDependency.ps1

$currentFileName = (Get-Item $PSCommandPath).Name
Write-Host 
Write-Host "========================================"
Write-Host "    $currentFileName"
Write-Host "========================================"
Write-Host

$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

$HWSSetupPath = $json.HWSSetupPath
if (Test-Path -Path $HWSSetupPath -PathType Leaf) {
    # Quitar la marca "unblock" del archivo descargado
    Unblock-File -Path $HWSSetupPath
    $config = $json.HWSChannelConfig
    $RetailServerURL = $json.RetailServerURL

    # Construye el comando usando las variables
    # $command = "HardwareStation.exe install --Port $port --CSUURL `"$csuUrl`" --StoreSystemChannelDatabaseID `"$storeSystemChannelDatabaseID`" --CertThumbprint `"$certThumbprint`""
    $command = "$HWSSetupPath install --Config `"$config`""`
                + " --csuurl `"$RetailServerURL`"" `
                + "--port 451"`
                # + $(if ($skipOPOSCheck) { " --skipOPOSCheck"} )`
                # + "--CertFullPath `"store:///My/LocalMachine?FindByThumbprint=372E6183EBCD266B984994CA24075E1C86493E9F`""


    # Ejecuta el comando
    write-host $command
    Invoke-Expression $command
}