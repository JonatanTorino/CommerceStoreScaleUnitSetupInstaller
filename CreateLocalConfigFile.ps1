. .\Support\SupportFunctions.ps1
CurrentFileName $MyInvocation.MyCommand.Name

# Crear archivo
$hostname = $env:COMPUTERNAME
$configFolder = ".\ConfigFiles"
$jsonFile = "$configFolder\$hostname.json"
$fileCount = (Get-ChildItem -Path $configFolder -Filter "$hostname*" -File | Measure-Object).Count
$jsonBackupFile = ""
if ($fileCount -gt 0) {
    $jsonBackupFile = "$hostname.BK$fileCount.json"
    Rename-Item $jsonFile -NewName $jsonBackupFile
}
Copy-Item "$configFolder\SAMPLE_Config_By_Env_(DuplicateAndRename).json" $jsonFile

# Cargar archivo
$json = Get-Content $jsonFile | ConvertFrom-Json

# Seteo de configuraciones
$json.EnvironmentId = GetEnvironmentId("AOSService")

$RetailServerURL = GetWebSiteUrl('RetailServer')
$json.RetailServerURL = "$RetailServerURL/RetailServer/Commerce"
$json.CPOSUrl = "$RetailServerURL/POS"
$json.Thumbprint = GetWebSiteCertThumbprint("AOSService")

# Cargar archivo backup para recuperar algunas propiedades
if ($fileCount -gt 0) {
    $jsonBackup = Get-Content "$configFolder\$jsonBackupFile" | ConvertFrom-Json
    
    # Versión anterior del json
    if ($null -ne $jsonBackup.ScaleUnitSetupPath) {
        $json.CSUSetupPath = $jsonBackup.ScaleUnitSetupPath
    }
    if ($null -ne $jsonBackup.ChannelConfig) {
        $json.CSUChannelConfig = $jsonBackup.ChannelConfig
    }
    if ($null -ne $jsonBackup.HttpPort) {
        $json.CSUHttpPort = $jsonBackup.HttpPort
    }

    #Versión nueva del json
    if ($null -ne $jsonBackup.HWSSetupPath) {
        $json.HWSSetupPath = $jsonBackup.HWSSetupPath
    }
    if ($null -ne $jsonBackup.HWSChannelConfig) {
        $json.HWSChannelConfig = $jsonBackup.HWSChannelConfig
    }
    if ($null -ne $jsonBackup.CSUSetupPath) {
        $json.CSUSetupPath = $jsonBackup.CSUSetupPath
    }
    if ($null -ne $jsonBackup.CSUChannelConfig) {
        $json.CSUChannelConfig = $jsonBackup.CSUChannelConfig
    }
    if ($null -ne $jsonBackup.CSUHttpPort) {
        $json.CSUHttpPort = $jsonBackup.CSUHttpPort
    }
    
    $json.TelemetryAppName = $jsonBackup.TelemetryAppName
    $json.AppInsightsInstrumentationKey = $jsonBackup.AppInsightsInstrumentationKey
    $json.RetailServerAadClientId = $jsonBackup.RetailServerAadClientId
    $json.CposAadClientId = $jsonBackup.CposAadClientId
    $json.AsyncClientAadClientId = $jsonBackup.AsyncClientAadClientId
    $json.IntervalAsyncClient = $jsonBackup.IntervalAsyncClient
}

# Guardado del archivo
$json | ConvertTo-Json | Out-File $jsonFile
