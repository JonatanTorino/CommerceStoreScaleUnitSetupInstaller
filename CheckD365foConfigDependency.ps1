[CmdletBinding()]
param (
    [string]
    [ValidateNotNullOrEmpty()]$jsonFile
)

Write-Host 
Write-Host "========================================"
Write-Host "        CheckD365foConfigDependency     "
Write-Host "========================================"
Write-Host 

$bindingsList = Get-IISSiteBinding "AOSService"
$urlBinding = ""

foreach ($binding in $bindingsList | Where-Object -Property bindingInformation -like "*aos.*") {
    #Write-Host "guardar uri en una variable < "$binding.bindingInformation 
    $urlBinding = $binding.Host
}


#Parseo el archivo json para leer sus propiedades
$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

#Inicializo cada variable del json
$RetailServerAadClientId=$json.RetailServerAadClientId
$CposAadClientId=$json.CposAadClientId
$AsyncClientAadClientId=$json.AsyncClientAadClientId
$config=$json.ChannelConfig

#Obtento el TenantId del archivo ChannelConfig referenciado en el json de configuración
[xml]$configXml = Get-Content $config
$xPath = "/configuration/appSettings/add[@key='TenantId']/@value"
$tenantId = Select-Xml -Xml $configXml -XPath $xPath 

$url = "https://$urlBinding"

Write-Host "Primera configuracion"
$miSysAADClientTable = $url+"/?mi=SysAADClientTable&lng=en-us"
Write-Host -ForegroundColor yellow "Revisar que esten cargados todos los ClientId"
Write-Host $miSysAADClientTable
Start-Process $miSysAADClientTable
Write-Host
Write-Host "Ingresar la siguiente, respetando los mismos nombres (necesario para que los movimientos de DB entre entornos T1 no tengan problemas) "
Write-Host
Write-Host "-----------------------------------------------------------------------------------------------------"
Write-Host "| ClientId: $CposAadClientId | Name: Cmm-POS     | UserID: RetailServiceAccount |"
Write-Host "| ClientId: $RetailServerAadClientId | Name: Cmm-RS      | UserID: RetailServiceAccount |"
Write-Host "| ClientId: $AsyncClientAadClientId | Name: Cmm-Async   | UserID: RetailServiceAccount |"
Write-Host "-----------------------------------------------------------------------------------------------------"
Write-Host
Pause

Write-Host
Write-Host "Segunda configuracion"
$miRetailSharedParameters = $url+"/?mi=RetailSharedParameters&lng=en-us"
Write-Host 
Write-Host -ForegroundColor yellow "Revisar que esten cargados las configuraciones en CommerceSharedParameters > Identity Providers"
Write-Host $miRetailSharedParameters
Start-Process $miRetailSharedParameters
Write-Host 
Write-Host "Este pantalla cuenta con 3 grillas, cada grilla de inferior esta invuclada con el registro de la grilla superior"
Write-Host 
Write-Host "Grilla IDENTITY PROVIDERS: crear un solo registro (si no existe) con el TenantId que esta en el archivo ChannelConfig  "
Write-Host
Write-Host "-----------------------------------------------------------------------------------------------------------------------"
Write-Host "| Issuer: https://sts.windows.net/$tenantId | Name: Cmm-CSU | Type: Azure Active Directory |"
Write-Host "-----------------------------------------------------------------------------------------------------------------------"
Write-Host
#Pause
Write-Host 
Write-Host "Grilla RELYING PARTIES: crear un solo registro, vinculado al TenantId creado anteriormente"
Write-Host 
Write-Host "----------------------------------------------------------------------------------------------------"
Write-Host "| ClientId: $CposAadClientId | Type: Public | UserType: Worker | Name: CSU-POS |"
Write-Host "----------------------------------------------------------------------------------------------------"
Write-Host 
#Pause
Write-Host 
Write-Host "Grilla SERVER RESOURCE IDS: crear un solo registro, vinculado al RELYING PARTIES creado anteriormente"
Write-Host 
Write-Host "----------------------------------------------------------------------------------"
Write-Host "| ServerResourceIds: 'api://$RetailServerAadClientId' | Name: CSU-RS |"
Write-Host "----------------------------------------------------------------------------------"
Write-Host 

# Write-Host "Presione una tecla para continuar"
# [Console]::ReadKey()
Pause
