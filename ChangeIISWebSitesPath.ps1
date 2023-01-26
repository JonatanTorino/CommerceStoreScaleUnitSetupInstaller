#Requires -RunAsAdministrator

$ScaleUnitPath = 'C:\Program Files\Microsoft Dynamics 365\10.0\Commerce Scale Unit\Microsoft\'
$ScaleUnitPathPOS = $ScaleUnitPath+'POS'
$ScaleUnitPathRetailServer = $ScaleUnitPath+'RetailServer'

Import-Module WebAdministration

Set-ItemProperty IIS:\Sites\RetailCloudPos -name physicalPath -value $ScaleUnitPathPOS
Write-Host -ForegroundColor Yellow 'Se reemplazo el path del WebSite RetailCloudPOS, nuevo path:'
Write-Host $ScaleUnitPathPOS

Set-ItemProperty IIS:\Sites\RetailServer -name physicalPath -value $ScaleUnitPathRetailServer 
Write-Host -ForegroundColor Yellow 'Se reemplazo el path del WebSite RetailServer, nuevo path:'
Write-Host $ScaleUnitPathRetailServer