function GetCertThumbprint {
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
    # Imprime el thumbprint del certificado
    return $certificado
}

# Crear archivo
$hostname = $env:COMPUTERNAME
$jsonFile = ".\ConfigFiles\$hostname.json"
Copy-Item ".\ConfigFiles\SAMPLE_Config_By_Env_(DuplicateAndRename).json" $jsonFile

# Cargar archivo
$json = Get-Content $jsonFile | ConvertFrom-Json

# Seteo de configuraciones
$urlEnvironment = Get-D365Url
$urlEnvironment = $urlEnvironment.Url
$json.RetailServerURL = "$urlEnvironment/RetailServer/Commerce"
$json.Thumbprint = GetCertThumbprint("AOSService")
$json.EnvironmentId

# Guardado del archivo
$json | ConvertTo-Json | Out-File $jsonFile
