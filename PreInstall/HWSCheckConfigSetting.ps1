[CmdletBinding()]
param (
    [string]
    [ValidateNotNullOrEmpty()]$jsonFile
)

. .\Support\SupportFunctions.ps1
PrintFileName $MyInvocation.MyCommand.Name

if (-not (Test-Path $jsonFile)) {
    throw [System.IO.FileNotFoundException] "$jsonFile not found."
}

#Parseo el archivo json para leer sus propiedades
$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

#Inicializo cada variable del json
$config = $json.HWSChannelConfig

#Comprobamos existencia del xml del ChannelConfig obtenido de D365FO
if (-not (Test-Path $config)) {
    Write-Host -ForegroundColor Yellow "Falta especificar o descargar el archivo XMl de HwsConfig"
    Write-Host -ForegroundColor Yellow "Se descarga desde la ruta"
    Write-Host -ForegroundColor Yellow "D365FO > Retail and Commerce > Channels > Stores > All stores > Hardware station > [Store] > Hardware stations"
    Pause
    
    #Inicializo las URLs de los MenuItems que se van usar.
    $url = GetAosServiceUrl
    $miRetailStoreTable = $url + "/?mi=RetailStoreTable&lng=en-us"

    Start-Process $miRetailStoreTable
    throw [System.IO.FileNotFoundException] "$config not found."
}

# Comprobar si se usa un certificado local o se considera una VM Cloud de desarrollo
$HwsIsLocalCertificate = $json.HWSIsLocalCertificate
if ($null -eq $HwsIsLocalCertificate)
{
    throw "Al archivo $jsonFile le falta la propiedad booleana HWSIsLocalCertificate."
}

[xml]$HwsConfigXml = Get-Content $config

# Helper function to ensure a node exists in the XML
function EnsureNodeExists {
    param (
        [xml]$xmlDocument,
        [string]$xPath,
        [string]$key,
        [string]$value
    )
    $existingNode = $xmlDocument.SelectSingleNode($xPath)
    if ($null -eq $existingNode) {
        $newNode = $xmlDocument.CreateElement('add')
        $newNode.SetAttribute('key', $key)
        $newNode.SetAttribute('value', $value)
        $appSettingsNode = $xmlDocument.SelectSingleNode('/configuration/appSettings')
        $appSettingsNode.AppendChild($newNode) | Out-Null
        Write-Host -ForegroundColor Green "Node with key '$key' added."
    } else {
        Write-Host -ForegroundColor Yellow "Node with key '$key' already exists. Skipping."
    }
}

# Ensure the separator node exists
$separator = '------------------'
$xPathSeparator = "/configuration/appSettings/add[@key='$separator']"
EnsureNodeExists -xmlDocument $HwsConfigXml -xPath $xPathSeparator -key $separator -value $separator

# Obtengo el nodo 'add' con key='HardwareStationCertificateThumbprint' para extraer el atributo 'value'
$xPathHardwareStationCertificateThumbprint = "/configuration/appSettings/add[@key='HardwareStationCertificateThumbprint']/@value"
$HardwareStationCertificateThumbprint = (Select-Xml -Xml $HwsConfigXml -XPath $xPathHardwareStationCertificateThumbprint).Node.Value

# Ensure CertThumbprint node exists
if ($true -eq $HwsIsLocalCertificate) {
    $localhostCertThumbprint = GetLocalHostNameCertificateThumbprint
    EnsureNodeExists -xmlDocument $HwsConfigXml -xPath "/configuration/appSettings/add[@key='CertThumbprint']" -key 'CertThumbprint' -value $localhostCertThumbprint
} else {
    EnsureNodeExists -xmlDocument $HwsConfigXml -xPath "/configuration/appSettings/add[@key='CertThumbprint']" -key 'CertThumbprint' -value $HardwareStationCertificateThumbprint
}

# Obtengo el nodo 'add' con key='HardwareStationHostName' para extraer el atributo 'value'
$xPathHardwareStationHostName = "/configuration/appSettings/add[@key='HardwareStationHostName']/@value"
$HardwareStationHostName = (Select-Xml -Xml $HwsConfigXml -XPath $xPathHardwareStationHostName).Node.Value

# Ensure HostName node exists
EnsureNodeExists -xmlDocument $HwsConfigXml -xPath "/configuration/appSettings/add[@key='HostName']" -key 'HostName' -value $HardwareStationHostName

# Ensure SkipOPOSCheck node exists
EnsureNodeExists -xmlDocument $HwsConfigXml -xPath "/configuration/appSettings/add[@key='SkipOPOSCheck']" -key 'SkipOPOSCheck' -value 'true'

# Ensure HardwareStationAppInsightsInstrumentationKey node exists
$AppInsightsInstrumentationKey = $json.AppInsightsInstrumentationKey
EnsureNodeExists -xmlDocument $HwsConfigXml -xPath "/configuration/appSettings/add[@key='HardwareStationAppInsightsInstrumentationKey']" -key 'HardwareStationAppInsightsInstrumentationKey' -value $AppInsightsInstrumentationKey

# Save the changes to the XML file
$HwsConfigXml.Save($config)
