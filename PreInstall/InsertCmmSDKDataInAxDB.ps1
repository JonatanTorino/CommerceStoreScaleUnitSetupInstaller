[CmdletBinding()]
param (
    [string]
    # [ValidateNotNullOrEmpty()]
    $jsonFile
)

Write-Host 
Write-Host "========================================"
Write-Host "     Inserting in AxDB the AadClientIds and Commerce Profile    "
Write-Host "========================================"
Write-Host 

$GetJsonConfigFile = ".\Support\GetJsonConfigFile.ps1"
$jsonFile = & $GetJsonConfigFile -JsonFile $jsonFile

# Parámetros de conexión a la base de datos
$server = $env:COMPUTERNAME

#Parseo el archivo json para leer sus propiedades
$json = Get-Content $jsonFile -Raw | ConvertFrom-Json
$channelConfig=$json.CSUChannelConfig

#Obtento el TenantId del archivo ChannelConfig referenciado en el json de configuración
[xml]$channelConfigXml = Get-Content $channelConfig
$xPathTenantId = "/configuration/appSettings/add[@key='TenantId']/@value"
$xPathStoreSystemChannelDatabaseId = "/configuration/appSettings/add[@key='StoreSystemChannelDatabaseId']/@value"
$TenantId = Select-Xml -Xml $channelConfigXml -XPath $xPathTenantId 
$StoreSystemChannelDatabaseId = Select-Xml -Xml $channelConfigXml -XPath $xPathStoreSystemChannelDatabaseId

#Inicializo cada variable del json
[string]$RetailServerAadClientId=$json.RetailServerAadClientId
[string]$CposAadClientId=$json.CposAadClientId
[string]$AsyncClientAadClientId=$json.AsyncClientAadClientId
[string]$RetailServerURL='"'+$json.RetailServerURL+'"'
[string]$CPOSURL='"'+$json.CPOSUrl+'"'

# Ruta del archivo SQL
$rutaScriptSQL = '.\InsertCmmSDKAzureActiveClientId.sql'

    try {
        # Ejecutar el script SQL
        SQLCMD -S $server -E -i $rutaScriptSQL -v AadPOSId=$CposAadClientId AadRetailServerId=$RetailServerAadClientId AadAsyncClientId=$AsyncClientAadClientId TenantId=$TenantId StoreSystemChannelDatabaseId=$StoreSystemChannelDatabaseId RetailServerURL=$RetailServerURL CPOSURL=$CPOSURL
    }
    catch {
        Write-Host "Error al ejecutar el script SQL: $_.Exception.Message"
    }

# Ruta del archivo SQL
$rutaScriptSQL = '.\InsertCmmSDKProfileConfig.sql'

    try {
        # Ejecutar el script SQL
        SQLCMD -S $server -E -i $rutaScriptSQL -v StoreSystemChannelDatabaseId=$StoreSystemChannelDatabaseId RetailServerURL=$RetailServerURL CPOSURL=$CPOSURL
    }
    catch {
        Write-Host "Error al ejecutar el script SQL: $_.Exception.Message"
    }
