[CmdletBinding()]
param (
    [string]
    [ValidateNotNullOrEmpty()]$jsonFile
)

Write-Host 
Write-Host "========================================"
Write-Host "     Inserting in AxDB the AadClientIds     "
Write-Host "========================================"
Write-Host 

# Parámetros de conexión a la base de datos
$server = $env:COMPUTERNAME
$database = "AxDB"

#Parseo el archivo json para leer sus propiedades
$json = Get-Content $jsonFile -Raw | ConvertFrom-Json
$config=$json.ChannelConfig

#Obtento el TenantId del archivo ChannelConfig referenciado en el json de configuración
[xml]$configXml = Get-Content $config
$xPathTenantId = "/configuration/appSettings/add[@key='TenantId']/@value"
$TenantId = Select-Xml -Xml $configXml -XPath $xPathTenantId 
$xPathStoreSystemChannelDatabaseId = "/configuration/appSettings/add[@key='StoreSystemChannelDatabaseId']/@value"
$StoreSystemChannelDatabaseId = Select-Xml -Xml $configXml -XPath $xPathStoreSystemChannelDatabaseId 

#Inicializo cada variable del json
[string]$RetailServerAadClientId=$json.RetailServerAadClientId
[string]$CposAadClientId=$json.CposAadClientId
[string]$AsyncClientAadClientId=$json.AsyncClientAadClientId

# Ruta del archivo SQL
$rutaScriptSQL = '.\setCommerceSDK_AzureActiveDirectoryKeys.sql'

try {
    # Ejecutar el script SQL
    SQLCMD -S $server -E -i $rutaScriptSQL -v AadPOSId=$CposAadClientId AadRetailServerId=$RetailServerAadClientId AadAsyncClientId=$AsyncClientAadClientId TenantId=$TenantId StoreSystemChannelDatabaseId=$StoreSystemChannelDatabaseId
}
catch {
    Write-Host "Error al ejecutar el script SQL: $_.Exception.Message"
}

    # # Definir las variables para el script SQL
    # $variables = @{
    #     "AadPOSId" = $CposAadClientId
    #     "AadRetailServerId" = $RetailServerAadClientId
    #     "AadAsyncClientId" = $AsyncClientAadClientId
    #     "TenantId" = $TenantId
    # }

    # # Construir cadena de conexión
    # $connectionString = "Server=.;Database=$database;Integrated Security=True;"

    # # Leer el contenido del archivo SQL
    # $scriptSQL = Get-Content -Path $rutaScriptSQL -Raw

    # # Reemplazar los parámetros en el script SQL
    # $scriptSQL = $scriptSQL -replace "@param1", $param1 -replace "@param2", $param2

    # try {
    #     Ejecutar el script SQL
    #     Invoke-Sqlcmd -ServerInstance $server -Database $database -ConnectionString $connectionString -InputFile $rutaScriptSQL -Variable $variables
    # }
    # catch {
    #     Write-Host "Error al ejecutar el script SQL: $_.Exception.Message"
    # }
