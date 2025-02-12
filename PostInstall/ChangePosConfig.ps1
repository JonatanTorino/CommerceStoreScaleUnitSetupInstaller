#Requires -RunAsAdministrator

param ( #Recibir valor en este formato 00:01:00
[parameter(Mandatory = $true
    , HelpMessage = "Ingresar URL del RetailServer]")
]
[string]
[ValidateNotNullOrEmpty()]$urlRetailServerCommerce
) 

$currentFileName = (Get-Item $PSCommandPath).Name
Write-Host 
Write-Host "========================================"
Write-Host "    $currentFileName"
Write-Host "========================================"
Write-Host 

$originalPath = Get-Location

$path = "C:\Program Files\Microsoft Dynamics 365\10.0\Commerce Scale Unit\Microsoft\POS\"
Set-Location $path
Copy-Item "config.json" "config.json.backup"

$jsonFile = "config.json"
$json = Get-Content $jsonFile -Raw | ConvertFrom-Json
$json.RetailServerUrl = $urlRetailServerCommerce

$json | ConvertTo-Json -Compress -depth 32 | Out-File $jsonFile

Set-Location $originalPath