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
$ChannelConfig = $json.ChannelConfig

#Comprobamos existencia del xml del ChannelConfig obtenido de D365FO
if (-not (Test-Path $ChannelConfig)) {
    Write-Host -ForegroundColor Yellow "Falta especificar o descargar el archivo XMl de ChannelConfig"
    Write-Host -ForegroundColor Yellow "Se descarga desde la ruta"
    Write-Host -ForegroundColor Yellow "D365FO > Retail and commerce > Headquarters setup > Commerce scheduler > Channel database"
    Pause
    
#Inicializo las URLs de los MenuItems que se van usar.
    $url = GetAosServiceUrl
    $miRetailCDXDataStore = $url + "/?mi=RetailStoreTable&lng=en-us"

    Start-Process $miRetailCDXDataStore
    throw [System.IO.FileNotFoundException] "$ChannelConfig not found."
}

#Obtento el TenantId del archivo ChannelConfig referenciado en el json de configuración
[xml]$ChannelConfigXml = Get-Content $ChannelConfig
$xPathAsyncClientAppInsightsInstrumentationKey = "/configuration/appSettings/add[@key='AsyncClientAppInsightsInstrumentationKey']/@value"
$xPathCloudPosAppInsightsInstrumentationKey = "/configuration/appSettings/add[@key='CloudPosAppInsightsInstrumentationKey']/@value"
$xPathRetailServerAppInsightsInstrumentationKey = "/configuration/appSettings/add[@key='RetailServerAppInsightsInstrumentationKey']/@value"

$AsyncClientAppInsightsInstrumentationKey = Select-Xml -Xml $ChannelConfigXml -XPath $xPathAsyncClientAppInsightsInstrumentationKey
$CloudPosAppInsightsInstrumentationKey = Select-Xml -Xml $ChannelConfigXml -XPath $xPathCloudPosAppInsightsInstrumentationKey
$RetailServerAppInsightsInstrumentationKey = Select-Xml -Xml $ChannelConfigXml -XPath $xPathRetailServerAppInsightsInstrumentationKey

if ($null -eq $AsyncClientAppInsightsInstrumentationKey.Node.Value -Or 
    $null -eq $CloudPosAppInsightsInstrumentationKey.Node.Value -Or 
    $null -eq $RetailServerAppInsightsInstrumentationKey.Node.Value)
{
    throw "El archivo $ChannelConfig tiene AppInsightsInstrumentationKey faltantes."
}

$xPathEnvironmentId  = "/configuration/appSettings/add[@key='EnvironmentId']/@value"
$EnvironmentId = Select-Xml -Xml $ChannelConfigXml -XPath $xPathEnvironmentId
$EnvironmentIdjson = $json.EnvironmentId -replace '"', ''
$EnvironmentIdXml = $EnvironmentId.Node.Value
if ($null -eq $EnvironmentId.Node.Value)
{
    throw "El archivo $ChannelConfig tiene EnvironmentId faltante."
}
if ($json.EnvironmentId -ne $EnvironmentId.Node.Value)
{
    Write-Host "JsonFile        EnvironmentId $EnvironmentIdjson"
    Write-Host "ChannelConfig   EnvironmentId $EnvironmentIdXml"
    throw "El archivo $ChannelConfig tiene un EnvironmentId diferente al del $jsonFile"
}
