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

$jsonFile = GetJsonConfig -jsonFile $jsonFile -Suffix "HWS"

if ([string]::IsNullOrEmpty($jsonFile)) {
    throw [System.ArgumentNullException] "jsonFile" 
}

.\PreInstall\CheckRegeditEntriesDependency.ps1
.\PreInstall\HWSInstallDependencies.ps1
.\PreInstall\HWSCheckConfigSetting.ps1 $jsonFile

PrintFileName $MyInvocation.MyCommand.Name

$hws = Get-HWSParameters $jsonFile

if (Test-Path -Path $hws.SetupPath -PathType Leaf) {
    # Quitar la marca "unblock" del archivo descargado
    Unblock-File -Path $hws.SetupPath

    # Construye el comando usando las variables
    $command = "$($hws.SetupPath) install --Config `"$($hws.Config)`""`
                + " --csuurl `"$($hws.RetailServerURL)`"" `
                + "--port $($hws.HttpPort)"`
    # Ej de como usar condicionales para concatenar parámetros
        # + $(if ($skipOPOSCheck) { " --skipOPOSCheck"} )`

    # Ejecuta el comando y captura la salida y el código de salida
    Write-Log $command "Blue"
    Invoke-Expression $command
    $exitCode = $LASTEXITCODE

    # Verifica el código de salida
    if ($exitCode -eq 0) {
        Write-Log "El comando se ejecutó correctamente." "Green"
    } else {
        Write-Log "El comando falló con el código de salida: $exitCode" "Red"
    }
}
else {
    Write-Log "ARCHIVO INSTALADOR NO ENCONTRADO. Ruta buscada: '$($hws.SetupPath)'. Verifique la propiedad HWSSetupPath en el archivo de configuración JSON." "Red"
}
