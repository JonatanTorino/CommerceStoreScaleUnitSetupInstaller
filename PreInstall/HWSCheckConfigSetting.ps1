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

#Comprobamos existencia del xml del ChannelConfig obtenido de D365FO
if (-not (Test-Path $ChannelConfig)) {
    Write-Host -ForegroundColor Yellow "Falta especificar o descargar el archivo XMl de HwsConfig"
    Write-Host -ForegroundColor Yellow "Se descarga desde la ruta"
    Write-Host -ForegroundColor Yellow "D365FO > Retail and Commerce > Channels > Stores > All stores > Hardware station > [Store] > Hardware stations"
    Pause
    
#Inicializo las URLs de los MenuItems que se van usar.
    Import-Module .\Support\SupportFunctions.ps1
    $url = GetWebSiteUrl("AOSService") 
    $miRetailStoreTable = $url + "/?mi=RetailStoreTable&lng=en-us"

    Start-Process $miRetailStoreTable
    throw [System.IO.FileNotFoundException] "$ChannelConfig not found."
}

# Comprobar si se usa un certificado local o se considera una VM Cloud de desarrollo
$HwsIsLocalCertificate = $json.HWSIsLocalCertificate
if ($null -eq $HwsIsLocalCertificate)
{
    throw "Al archivo $jsonFile le falta la propiedad booleana HWSIsLocalCertificate."
}

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
