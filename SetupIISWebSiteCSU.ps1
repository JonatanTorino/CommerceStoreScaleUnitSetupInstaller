#Requires -RunAsAdministrator

param ( #Recibir valor en este formato 00:01:00
[parameter(Mandatory = $true
    , HelpMessage = "Ingresar URL del RetailServer")
]
[string]
[ValidateNotNullOrEmpty()]$retailServerURL
) 

$currentFileName = (Get-Item $PSCommandPath).Name
Write-Host 
Write-Host "========================================"
Write-Host "    $currentFileName"
Write-Host "========================================"
Write-Host 

# Usa el objeto System.Uri para obtener el hostname
$uri = [System.Uri]::new($retailServerURL)

# Define el nombre del sitio, nuevo hostname, nuevo puerto y nombre del certificado
$siteName = "RetailStoreScaleUnitWebSite.AspNetCore"  # Cambia este valor por el nombre de tu WebSite
$newHostname = $uri.Host
$newPort = 443  # Puerto HTTPS

# Usa -replace para realizar el cambio solo en la parte que te interesa
# El patrón asegura que solo se reemplace 'ret' antes de '.axcloud.dynamics.com'
$certName = $newHostname -replace "ret(?=\.axcloud\.dynamics\.com)", "aos"
$certThumbprint = (Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*$certName*" }).Thumbprint

# Verifica si el sitio web existe
$site = Get-Website | Where-Object { $_.Name -eq $siteName }
if ($null -eq $site) {
    Write-Host "El sitio web no existe" -ForegroundColor Red
    exit
}

# Obtén todos los bindings del sitio web
$bindings = Get-WebBinding -Name $siteName

# Recorre y elimina cada binding
foreach ($binding in $bindings) {
    Remove-WebBinding -Name $siteName -BindingInformation $binding.BindingInformation -Protocol $binding.Protocol
}

# Asigna el certificado SSL
New-WebBinding -Name $siteName -IPAddress "*" -Port $newPort -HostHeader $newHostname -Protocol https
