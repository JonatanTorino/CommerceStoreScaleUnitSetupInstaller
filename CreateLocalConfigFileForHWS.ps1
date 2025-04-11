. .\Support\SupportFunctions.ps1
PrintFileName $MyInvocation.MyCommand.Name

# Crear archivo usando función reutilizable
$result = New-LocalConfigFile -ComponentSuffix "HWS"
$jsonFile = $result.ConfigFile
$jsonBackupFile = $result.BackupFile

# Cargar archivo
$json = Get-Content $jsonFile | ConvertFrom-Json

# Cargar archivo backup para recuperar algunas propiedades
if ($null -ne $jsonBackupFile) {
    $jsonBackup = Get-Content $jsonBackupFile | ConvertFrom-Json
    
    # Versión anterior del json HWS
    if ($null -ne $jsonBackup.HWSIsLocalCertificate) {
        $json.HWSIsLocalCertificate = $jsonBackup.HWSIsLocalCertificate
    }
    if ($null -ne $jsonBackup.HWSSetupPath) {
        $json.HWSSetupPath = $jsonBackup.HWSSetupPath
    }
    if ($null -ne $jsonBackup.HWSChannelConfig) {
        $json.HWSChannelConfig = $jsonBackup.HWSChannelConfig
    }
    if ($null -eq $json.AppInsightsInstrumentationKey -and 
        $null -ne $jsonBackup.AppInsightsInstrumentationKey) {
        $json.AppInsightsInstrumentationKey = $jsonBackup.AppInsightsInstrumentationKey
    }
}

# Guardado del archivo
$json | ConvertTo-Json | Out-File $jsonFile
