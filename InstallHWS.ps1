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
    Write-Host -ForegroundColor Red "   $($csu.SetupPath)"
    Write-Host -ForegroundColor Red "Revisar la configuración del json.HWSSetupPath que tenga la ruta completa al instalador"
}
