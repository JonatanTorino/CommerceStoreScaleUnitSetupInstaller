. .\Support\SupportFunctions.ps1
PrintFileName $MyInvocation.MyCommand.Name

# Crear archivo usando función reutilizable
$jsonFile = Create-LocalConfigFile -ComponentSuffix "HWS"

# Cargar archivo
$json = Get-Content $jsonFile | ConvertFrom-Json

if (ExistsAosServiceFolder -and HasInstalledIIS) {
    $RetailServerURL = GetWebSiteUrl('RetailServer')
    $json.RetailServerURL = "$RetailServerURL/RetailServer/Commerce"
}

# Cargar archivo backup para recuperar algunas propiedades
if ($fileCount -gt 0) {
    $jsonBackup = Get-Content "$configFolder\$jsonBackupFile" | ConvertFrom-Json
    
    # Versión anterior del json HWS
    if ($null -ne $jsonBackup.HWSIsLocalCertificate) {
        $json.HWSIsLocalCertificate = $jsonBackup.HWSIsLocalCertificate
    }
    if ($null -eq $json.RetailServerURL -and 
        $null -ne $jsonBackup.RetailServerURL) {
        $json.RetailServerURL = $jsonBackup.RetailServerURL
    }
    if ($null -ne $jsonBackup.HWSSetupPath) {
        $json.HWSSetupPath = $jsonBackup.HWSSetupPath
    }
    if ($null -ne $jsonBackup.HWSChannelConfig) {
        $json.HWSChannelConfig = $jsonBackup.HWSChannelConfig
    }
}

# Guardado del archivo
$json | ConvertTo-Json | Out-File $jsonFile
