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

$jsonFile = GetJsonConfig -jsonFile $jsonFile -Suffix "CSU"

# Parámetros de conexión a la base de datos
$server = $env:COMPUTERNAME

#Parseo el archivo json para leer sus propiedades
$csu = . Get-CSUParameters $jsonFile 
$channelConfig = $csu.ChannelConfig

#Obtento el TenantId del archivo ChannelConfig referenciado en el json de configuración
[xml]$channelConfigXml = Get-Content $channelConfig
$xPathTenantId = "/configuration/appSettings/add[@key='TenantId']/@value"
$xPathStoreSystemChannelDatabaseId = "/configuration/appSettings/add[@key='StoreSystemChannelDatabaseId']/@value"
$TenantId = Select-Xml -Xml $channelConfigXml -XPath $xPathTenantId 
$StoreSystemChannelDatabaseId = Select-Xml -Xml $channelConfigXml -XPath $xPathStoreSystemChannelDatabaseId

#Inicializo cada variable del json
[string]$RetailServerAadClientId = $csu.RetailServerAadClientId
[string]$CposAadClientId = $csu.CposAadClientId
[string]$AsyncClientAadClientId = $csu.AsyncClientAadClientId
[string]$RetailServerURL = '"' + $csu.RetailServerURL + '"'
[string]$CPOSURL = '"' + $csu.CPOSUrl + '"'

# Ruta del archivo SQL
$rutaScriptSQL = '.\PreInstall\InsertCmmSDKAzureActiveClientId.sql'

    try {
        # Ejecutar el script SQL
        SQLCMD -S $server -E -i $rutaScriptSQL -v AadPOSId=$CposAadClientId AadRetailServerId=$RetailServerAadClientId AadAsyncClientId=$AsyncClientAadClientId TenantId=$TenantId StoreSystemChannelDatabaseId=$StoreSystemChannelDatabaseId RetailServerURL=$RetailServerURL CPOSURL=$CPOSURL
    }
    catch {
        Write-Host "Error al ejecutar el script SQL: $_.Exception.Message"
    }

# Ruta del archivo SQL
$rutaScriptSQL = '.\PreInstall\InsertCmmSDKProfileConfig.sql'

    try {
        # Ejecutar el script SQL
        SQLCMD -S $server -E -i $rutaScriptSQL -v StoreSystemChannelDatabaseId=$StoreSystemChannelDatabaseId RetailServerURL=$RetailServerURL CPOSURL=$CPOSURL
    }
    catch {
        Write-Host "Error al ejecutar el script SQL: $_.Exception.Message"
    }
