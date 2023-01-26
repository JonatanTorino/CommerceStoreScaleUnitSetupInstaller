#Requires -RunAsAdministrator

param ( #Recibir valor en este formato 00:01:00
    [parameter(Mandatory = $true
        , HelpMessage = "Ingresar nuevo intervalo con el siguiente formato ##:##:##")
    ]
    [string]
    [ValidateNotNullOrEmpty()]$newInterval
) 

Write-Host 
Write-Host "========================================"
Write-Host "            ChangeAsyncInterval         "
Write-Host "========================================"
Write-Host 

$pathFile = "C:\Program Files\Microsoft Dynamics 365\10.0\Commerce Scale Unit\Microsoft\AsyncClient\AsyncClientService.exe.config"

if (Test-Path $pathFile) {

    Copy-Item $pathFile -Destination $pathFile".backup"

    $xml = [xml](Get-Content $pathFile)
    $newValue = $newInterval #Recibir valor en este formato '00:01:00'
    $xpath = "/configuration/applicationSettings/Microsoft.Dynamics.Retail.AsyncClient.Service.Properties.Settings/setting[@name='DownloadInterval']"
    $node = $xml.SelectSingleNode($xpath)
    $node.value = $newValue
    
    $xpath = "/configuration/applicationSettings/Microsoft.Dynamics.Retail.AsyncClient.Service.Properties.Settings/setting[@name='UploadInterval']"
    $node = $xml.SelectSingleNode($xpath)
    $node.value = $newValue
    
    $xml.Save($pathFile)

    Stop-Service -Name 'RetailStoreScaleUnitAsyncClientService'
    Start-Service -Name 'RetailStoreScaleUnitAsyncClientService'
}
else {
    Write-Host -ForegroundColor Red "No se logro instalar el ScaleUnit o no se encuentra el AsyncClientService en la ruta:"
    Write-Host -ForegroundColor Yellow $pathFile
}
