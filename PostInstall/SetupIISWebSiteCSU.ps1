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

#Cambio el puerto de WebSite RetailServer para reutilizar el 443
# Obtiene el binding con el puerto especificado
$RetailServer = "RetailServer"
$binding = Get-WebBinding -Name $RetailServer | Where-Object { $_.bindingInformation -like "*:${newPort}:*" }
if ($binding) {
    $dummyPort = 444
    # Obtiene la información del binding actual
    $bindingInfo = $binding.BindingInformation
    $protocol = $binding.Protocol

    # Elimina el binding con el puerto actual
    Remove-WebBinding -Name $RetailServer -BindingInformation $bindingInfo -Protocol $protocol

    # Crea un nuevo binding con el puerto actualizado
    # New-WebBinding -Name $RetailServer -BindingInformation $newBindingInfo -Protocol $protocol
    $binding = New-WebBinding -Name $RetailServer -IPAddress "*" -Port $dummyPort -HostHeader $newHostname -Protocol https

    Write-Host "El puerto del binding ha sido cambiado de $dummyPort a $newPort para el sitio $RetailServer."
} else {
    Write-Host "No se encontró un binding con el puerto $dummyPort en el sitio $RetailServer." -ForegroundColor Red
}

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
