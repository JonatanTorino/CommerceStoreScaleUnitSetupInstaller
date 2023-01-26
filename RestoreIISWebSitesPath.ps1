#Requires -RunAsAdministrator

$ScaleUnitPathPOS = 'K:\RetailCloudPos\WebRoot'
$ScaleUnitPathRetailServer = 'K:\RetailServer\WebRoot'

Import-Module WebAdministration

Set-ItemProperty IIS:\Sites\RetailCloudPos -name physicalPath -value $ScaleUnitPathPOS
Write-Host -ForegroundColor Yellow 'Se restauro el path del WebSite RetailCloudPOS, path:'
Write-Host $ScaleUnitPathPOS

Set-ItemProperty IIS:\Sites\RetailServer -name physicalPath -value $ScaleUnitPathRetailServer 
Write-Host -ForegroundColor Yellow 'Se restauro el path del WebSite RetailServer, path:'
Write-Host $ScaleUnitPathRetailServer