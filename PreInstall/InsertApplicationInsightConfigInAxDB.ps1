[CmdletBinding()]
param (
    [string]
    [ValidateNotNullOrEmpty()]$jsonFile
)

Write-Host 
Write-Host "========================================"
Write-Host "     Setting ApplicationInsight configuration in AxDB for telemtry     "
Write-Host "========================================"
Write-Host 

$GetJsonConfigFile = ".\Support\GetJsonConfigFile.ps1"
$jsonFile = & $GetJsonConfigFile -JsonFile $jsonFile

# Parámetros de conexión a la base de datos
$server = $env:COMPUTERNAME

#Parseo el archivo json para leer sus propiedades
$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

#Inicializo cada variable del json
[string]$AppInsightsInstrumentationKey=$json.AppInsightsInstrumentationKey
[string]$TelemetryAppName = $json.TelemetryAppName -replace '"', ''
[string]$EnvironmentId = $json.EnvironmentId -replace '"', ''

# Ruta del archivo SQL
$rutaScriptSQL = '.\PreInstall\InsertApplicationInsightConfigInAxDB.sql'
try {
    # Ejecutar el script SQL
    SQLCMD -S $server -E -i $rutaScriptSQL -v AppInsightsInstrumentationKey=$AppInsightsInstrumentationKey TelemetryAppName=$TelemetryAppName EnvironmentId=$EnvironmentId
}
catch {
    Write-Host "Error al ejecutar el script SQL: $_.Exception.Message"
}
