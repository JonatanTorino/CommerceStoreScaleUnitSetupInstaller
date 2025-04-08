[CmdletBinding()]
param (
    [string]
    [ValidateNotNullOrEmpty()]$jsonFile
)

$currentFileName = (Get-Item $PSCommandPath).Name
Write-Host 
Write-Host "========================================"
Write-Host "    $currentFileName"
Write-Host "========================================"
Write-Host

if (-not (Test-Path $jsonFile)) {
    throw [System.IO.FileNotFoundException] "$jsonFile not found."
}

#Parseo el archivo json para leer sus propiedades
$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

#Inicializo cada variable del json
$config = $json.HWSChannelConfig

[xml]$HwsConfigXml = Get-Content $config

# Obtengo el nodo 'add' con key='HardwareStationCertificateThumbprint' para extraer el atributo 'value'
$xPathHardwareStationCertificateThumbprint = "/configuration/appSettings/add[@key='HardwareStationCertificateThumbprint']/@value"
$HardwareStationCertificateThumbprint = (Select-Xml -Xml $HwsConfigXml -XPath $xPathHardwareStationCertificateThumbprint).Node.Value

# Crear un nuevo nodo 'add' con key='CertThumbprint' y el valor extraído
$certThumbprint = $HwsConfigXml.CreateElement('add')
$certThumbprint.SetAttribute('key', 'CertThumbprint')
$certThumbprint.SetAttribute('value', $HardwareStationCertificateThumbprint)

# Agregar el nuevo nodo al nodo 'appSettings'
$appSettingsNode = $HwsConfigXml.SelectSingleNode('/configuration/appSettings')
$appSettingsNode.AppendChild($certThumbprint) | Out-Null

# Obtengo el nodo 'add' con key='HardwareStationHostName' para extraer el atributo 'value'
$xPathHardwareStationHostName = "/configuration/appSettings/add[@key='HardwareStationHostName']/@value"
$HardwareStationHostName = (Select-Xml -Xml $HwsConfigXml -XPath $xPathHardwareStationHostName).Node.Value

# Crear un nuevo nodo 'add' con key='HostName' y el valor extraído
$hostName = $HwsConfigXml.CreateElement('add')
$hostName.SetAttribute('key', 'HostName')
$hostName.SetAttribute('value', $HardwareStationHostName)

# Agregar el nuevo nodo al nodo 'appSettings'
$appSettingsNode = $HwsConfigXml.SelectSingleNode('/configuration/appSettings')
$appSettingsNode.AppendChild($hostName) | Out-Null

# Nodos nuevos
# Crear un nuevo nodo 'add' con key='SkipOPOSCheck' y el valor 'true'
$skipOPOSCheck = $HwsConfigXml.CreateElement('add')
$skipOPOSCheck.SetAttribute('key', 'SkipOPOSCheck')
$skipOPOSCheck.SetAttribute('value', 'true')

# Agregar el nuevo nodo al nodo 'appSettings'
$appSettingsNode = $HwsConfigXml.SelectSingleNode('/configuration/appSettings')
$appSettingsNode.AppendChild($skipOPOSCheck) | Out-Null

# Crear un nuevo nodo 'add' con key='HardwareStationAppInsightsInstrumentationKey' y el valor 'true'
$AppInsightsInstrumentationKey = $json.AppInsightsInstrumentationKey
$HardwareStationAppInsightsInstrumentationKey = $HwsConfigXml.CreateElement('add')
$HardwareStationAppInsightsInstrumentationKey.SetAttribute('key', 'HardwareStationAppInsightsInstrumentationKey')
$HardwareStationAppInsightsInstrumentationKey.SetAttribute('value', $AppInsightsInstrumentationKey)

# Agregar el nuevo nodo al nodo 'appSettings'
$appSettingsNode = $HwsConfigXml.SelectSingleNode('/configuration/appSettings')
$appSettingsNode.AppendChild($HardwareStationAppInsightsInstrumentationKey) | Out-Null

# Guardar los cambios en el archivo XML
$HwsConfigXml.Save($config)
