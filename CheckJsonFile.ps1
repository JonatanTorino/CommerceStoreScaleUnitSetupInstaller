[CmdletBinding()]
param (
    [string]
    [ValidateNotNullOrEmpty()]$jsonFile
)

Write-Host 
Write-Host "==============================="
Write-Host "        Check Json File        "
Write-Host "==============================="
Write-Host 

if (-not (Test-Path $jsonFile)) {
    throw [System.IO.FileNotFoundException] "$jsonFile not found."
}

#Parseo el archivo json para leer sus propiedades
$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

#Inicializo cada variable del json
$ChannelConfig = $json.ChannelConfig

#Inicializo las URLs de los MenuItems que se van usar.
$bindingsList = Get-IISSiteBinding "AOSService"
$urlBinding = ""
foreach ($binding in $bindingsList | Where-Object -Property bindingInformation -like "*aos.*") {
    #Write-Host "guardar uri en una variable < "$binding.bindingInformation 
    $urlBinding = $binding.Host
}
$url = "https://$urlBinding"
$miRetailCDXDataStore = $url + "/?mi=RetailCDXDataStore&lng=en-us"

#Comprobamos existencia del xml del ChannelConfig obtenido de D365FO
if (-not (Test-Path $ChannelConfig)) {
    Write-Host -ForegroundColor Yellow "Falta especificar o descargar el archivo XMl de ChannelConfig"
    Write-Host -ForegroundColor Yellow "Se descarga desde la ruta"
    Write-Host -ForegroundColor Yellow "D365FO > Retail and commerce > Headquarters setup > Commerce scheduler > Channel database"
    Pause
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

if ($null -eq $AsyncClientAppInsightsInstrumentationKey.InnerText -Or 
    $null -eq $CloudPosAppInsightsInstrumentationKey.InnerText -Or 
    $null -eq $RetailServerAppInsightsInstrumentationKey.InnerText)
{
    throw "El archivo $ChannelConfig tiene AppInsightsInstrumentationKey faltantes."
}
