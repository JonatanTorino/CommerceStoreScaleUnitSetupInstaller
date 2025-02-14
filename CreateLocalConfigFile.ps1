function GetEnvironmentId {
    param (
        [string]$webSite
    )
    # Obtener la ruta del archivo web.config
    $webConfigPath = GetWebConfigPath($webSite)

    # Cargar el archivo XML
    [xml]$xmlConfig = Get-Content $webConfigPath

    # Definir el XPath para buscar el nodo con el atributo key="LCS.EnvironmentId"
    $xPath = "/configuration/appSettings/add[@key='LCS.EnvironmentId']/@value"

    # Seleccionar el nodo
    $environmentIdNode = Select-Xml -Xml $xmlConfig -XPath $xPath

    # Obtener el valor del nodo
    $environmentIdValue = $environmentIdNode.Node.Value

    return $environmentIdValue
}
function GetWebConfigPath {
    param (
        [string]$webSite
    )
    # Obtiene la información del sitio web
    $sitio = Get-WebSite -Name $webSite

    # Obtiene el directorio físico del sitio web
    $physicalPath = $sitio.physicalPath

    # Construye la ruta completa del archivo web.config
    $webConfigPath = Join-Path -Path $physicalPath -ChildPath "web.config"

    return $webConfigPath
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
$json.EnvironmentId = GetEnvironmentId("AOSService")

$RetailServerURL = GetWebSiteUrl('RetailServer')
$json.RetailServerURL = "$RetailServerURL/RetailServer/Commerce"
$json.CPOSUrl = "$RetailServerURL/POS"
$json.Thumbprint = GetWebSiteCertThumbprint("AOSService")

# Guardado del archivo
$json | ConvertTo-Json | Out-File $jsonFile
