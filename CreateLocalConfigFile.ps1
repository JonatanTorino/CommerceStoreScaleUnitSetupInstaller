function GetWebSiteCertThumbprint {
    param (
        [string]$webSite = "AOSService"
    )
    # Obtiene la información del sitio web
    $sitio = Get-WebSite -Name $webSite

    # Obtiene el binding principal
    $bindings = $sitio.bindings
    $binding = $bindings.Collection[0]
    
    # Obtiene el certificado asociado al binding
    $certificado = $binding.certificateHash
    
    return $certificado
}
function GetWebSiteUrl {
    param (
        [string]$webSite
    )
    # Obtiene la información del sitio web
    $sitio = Get-WebSite -Name $webSite

    # Obtiene el binding principal
    $bindings = $sitio.bindings
    $binding = $bindings.Collection[0]
    
    # Usar una expresión regular para extraer el host
    $hostSegment = [regex]::Match($binding.bindingInformation, ':\d+:(.+)$').Groups[1].Value
    $protocol = $binding.protocol
    $url =  $protocol + "://" + $hostSegment
    return $url
}

$currentFileName = (Get-Item $PSCommandPath).Name
Write-Host 
Write-Host "========================================"
Write-Host "    $currentFileName"
Write-Host "========================================"
Write-Host

# Crear archivo
$hostname = $env:COMPUTERNAME
$jsonFile = ".\ConfigFiles\$hostname.json"
if (-not (Test-Path $jsonFile)) {
    Copy-Item ".\ConfigFiles\SAMPLE_Config_By_Env_(DuplicateAndRename).json" $jsonFile
}

# Cargar archivo
$json = Get-Content $jsonFile | ConvertFrom-Json

# Seteo de configuraciones
$RetailServerURL = GetWebSiteUrl('RetailServer')
$json.RetailServerURL = "$RetailServerURL/Commerce"
$CPOSUrl = GetWebSiteUrl('RetailCloudPos')
$json.CPOSUrl = $CPOSUrl
$json.Thumbprint = GetWebSiteCertThumbprint("AOSService")
# TODO Falta averiguar como obtener este dato
# $json.EnvironmentId = 

# Guardado del archivo
$json | ConvertTo-Json | Out-File $jsonFile
