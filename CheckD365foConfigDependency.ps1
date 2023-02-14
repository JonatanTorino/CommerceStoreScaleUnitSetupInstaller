Write-Host 
Write-Host "========================================"
Write-Host "        CheckD365foConfigDependency     "
Write-Host "========================================"
Write-Host 

$bindingsList = Get-IISSiteBinding "AOSService"

foreach ($binding in $bindingsList | Where-Object -Property bindingInformation -like "*aos.*") {
    Write-Host "guardar uri en una variable < "$binding.bindingInformation 
}

$url = "https://AOSServices"
$miSysAADClientTable = $url+"/?mi=SysAADClientTable&lng=en-us"

Write-Host 
Write-Host -ForegroundColor yellow "Revisar que esten cargados todos los ClientId"
Write-Host $miSysAADClientTable
Write-Host "Configuración propuesta, para que todos los entornos manejen los mismos nombres (util "
Write-Host "UserID: RetailServiceAccount | Name: Cmm-POS"
Write-Host "UserID: RetailServiceAccount | Name: Cmm-RS"
Write-Host "UserID: RetailServiceAccount | Name: Cmm-Async"

$miRetailSharedParameters = $url+"/?mi=RetailSharedParameters&lng=en-us"
Write-Host 
Write-Host -ForegroundColor yellow "Revisar que esten cargados las configuraciones en CommerceSharedParameters > Identity Providers"
Write-Host "Este pantalla cuenta con 3 grillas, cada grilla de inferior está invuclada con el registro de la grilla superior"

Write-Host $miRetailSharedParameters
Write-Host "Grilla IDENTITY PROVIDERS: crear un solo registro (si no existe) con el TenantId que está EN EL ARCHIVO ChannelConfig  "
Write-Host "Issuer: https://sts.windows.net/TENANT-ID | Name: Cmm-CSU | Type: Azure Active Directory"
Write-Host 
Write-Host "Grilla RELYING PARTIES: crear un solo registro, vinculado al TenantId creado anteriormente"
Write-Host "ClientId: el que corresponde al POS | Type: Public | UserType: Worker | Name: CSU-POS"
Write-Host 
Write-Host "Grilla SERVER RESOURCE IDS: crear un solo registro, vinculado al RELYING PARTIES creado anteriormente"
Write-Host "ServerResourceIds: 'api://DEL RETAILSERVER' | Name: CSU-RS"
Write-Host 

# Write-Host "Presione una tecla para continuar"
# [Console]::ReadKey()
Pause
