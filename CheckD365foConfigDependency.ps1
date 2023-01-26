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
Write-Host -ForegroundColor yellow "Revisar que esten todos los ClientId cargados"
Write-Host $miSysAADClientTable
Write-Host "UserID: RetailServiceAccount | Name: Cmm-POS"
Write-Host "UserID: RetailServiceAccount | Name: Cmm-RS"
Write-Host "UserID: RetailServiceAccount | Name: Cmm-Async"

$miRetailSharedParameters = $url+"/?mi=RetailSharedParameters&lng=en-us"
Write-Host 
Write-Host -ForegroundColor yellow "Revisar que esten cargados:"
Write-Host $miRetailSharedParameters
Write-Host "IDENTITY PROVIDERS  | con Type = Azure Active Directory"
Write-Host "RELYING PARTIES     | con Type = Public y UserType = Worker"
Write-Host "SERVER RESOURCE IDS | con ServerResourceIds comenzando 'api://'"
Write-Host 

$miRetailSharedParameters = $url+"/?mi=RetailSharedParameters&lng=en-us"

# Write-Host "Presione una tecla para continuar"
# [Console]::ReadKey()
Pause
