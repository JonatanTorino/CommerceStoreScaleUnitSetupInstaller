#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Vuelve a aplicar en la AxDB todas las configuraciones que requiere el CSU.

.DESCRIPTION
    Pensado para ejecutarse después de restaurar un .bak de otro entorno sobre la AxDB,
    cuando el CSU ya está instalado y solo hace falta reconfigurar la base de datos.
    Ejecuta los mismos scripts SQL que InstallCSU.ps1 (todos idempotentes):
      - Telemetría / Application Insights (InsertApplicationInsightConfigInAxDB.ps1)
      - AadClientIds y perfil de Commerce SDK (InsertCmmSDKDataInAxDB.ps1)

.EXAMPLE
    cd K:\Repos\JonatanTorino\CommerceStoreScaleUnitSetupInstaller\; .\UpdateAxDBConfigForCSU.ps1
#>

[CmdletBinding()]
param (
    [string]$jsonFile
    ,
    [switch]$skipCheckGitRepoUpdated = $false
)

$ErrorActionPreference = 'Stop'

# Los scripts invocados usan rutas relativas a la raíz del repositorio
Push-Location -Path $PSScriptRoot
try {
    . .\Support\SupportFunctions.ps1

    if (!$skipCheckGitRepoUpdated) {
        .\Support\CheckGitRepoUpdated.ps1 . # el . representa el directorio actual
        Set-Location -Path $PSScriptRoot
    }

    PrintFileName $MyInvocation.MyCommand.Name

    $jsonFile = GetJsonConfig -jsonFile $jsonFile -Suffix "CSU"

    .\PreInstall\CSUCheckJsonFile.ps1 $jsonFile
    .\PreInstall\InsertApplicationInsightConfigInAxDB.ps1 $jsonFile
    .\PreInstall\InsertCmmSDKDataInAxDB.ps1 $jsonFile

    Write-Host
    Write-Host -ForegroundColor Green "Configuraciones del CSU aplicadas en la AxDB."
}
finally {
    Pop-Location
}
