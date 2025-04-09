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

$GetJsonConfigFile = ".\Support\GetJsonConfigFile.ps1"
$jsonFile = & $GetJsonConfigFile -JsonFile $jsonFile

if ([string]::IsNullOrEmpty($jsonFile)) {
    throw [System.ArgumentNullException] "jsonFile" 
}

.\PreInstall\CheckRegeditEntriesDependency.ps1
.\PreInstall\HWSCheckConfigSetting.ps1 $jsonFile

. .\Support\SupportFunctions.ps1
PrintFileName $MyInvocation.MyCommand.Name

$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

$HWSSetupPath = $json.HWSSetupPath
if (Test-Path -Path $HWSSetupPath -PathType Leaf) {
    # Quitar la marca "unblock" del archivo descargado
    Unblock-File -Path $HWSSetupPath
    $config = $json.HWSChannelConfig
    $RetailServerURL = $json.RetailServerURL
    
    [xml]$HwsConfigXml = Get-Content $config
    $xPathHardwareStationHttpsPort = "/configuration/appSettings/add[@key='HardwareStationHttpsPort']/@value"
    $HWSPort = (Select-Xml -Xml $HwsConfigXml -XPath $xPathHardwareStationHttpsPort).Node.Value

    # Construye el comando usando las variables
    $command = "$HWSSetupPath install --Config `"$config`""`
                + " --csuurl `"$RetailServerURL`"" `
                + "--port $HWSPort"`
    # Ej de como usar condicionales para concatenar parámetros
        # + $(if ($skipOPOSCheck) { " --skipOPOSCheck"} )`

    # Ejecuta el comando y captura la salida y el código de salida
    write-host $command -ForegroundColor Blue
    Invoke-Expression $command
    $exitCode = $LASTEXITCODE

    # Verifica el código de salida
    if ($exitCode -eq 0) {
        Write-Host -ForegroundColor Green "El comando se ejecutó correctamente."
    } else {
        Write-Host -ForegroundColor Red "El comando falló con el código de salida: $exitCode"
    }
}
else {
    Write-Host -ForegroundColor Red "ARCHIVO INSTALADOR NO ENCONTRADO"
    Write-Host -ForegroundColor Red "   $HWSSetupPath"
    Write-Host -ForegroundColor Red "Revisar la configuración del json.HWSSetupPath que tenga la ruta completa al instalador"
}
