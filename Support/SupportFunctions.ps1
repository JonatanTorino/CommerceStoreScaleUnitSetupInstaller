# SupportFunctions.ps1
# Descripción: Módulo con funciones de soporte reutilizables

# Definir información del módulo
$ModuleVersion = "1.0.0"
$Author = "Jonatan Torino"

Import-Module WebAdministration

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

function CurrentFileName {
    param (
        $currentFileName
    )
    # $currentFileName = $MyInvocation.MyCommand.Name
    Write-Host 
    Write-Host "========================================"
    Write-Host "    $currentFileName"
    Write-Host "========================================"
    Write-Host
}
