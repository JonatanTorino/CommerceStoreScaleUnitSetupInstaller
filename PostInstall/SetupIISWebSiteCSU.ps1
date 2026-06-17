#Requires -RunAsAdministrator

param (
    [parameter(Mandatory = $true, HelpMessage = "Ingresar URL del RetailServer")]
    [string]
    [ValidateNotNullOrEmpty()]$retailServerURL
) 

if ($PSVersionTable.PSVersion.Major -ge 6) {
    Write-Warning "El modulo WebAdministration de IIS no es compatible nativamente con PowerShell Core (7+)."
    Write-Warning "Re-ejecutando el script en Windows PowerShell 5.1..."
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -retailServerURL $retailServerURL
    exit $LASTEXITCODE
}

# Importar funciones de soporte resolviendo la ruta con $PSScriptRoot
. "$PSScriptRoot\..\Support\SupportFunctions.ps1"
PrintFileName $MyInvocation.MyCommand.Name

# Obtener hostname y puerto
$uri = [System.Uri]::new($retailServerURL)
$siteName = "RetailStoreScaleUnitWebSite.AspNetCore"
$newHostname = $uri.Host
$newPort = 443

# Obtener el certificado más reciente que coincida con el hostname/patrón
$certName = $newHostname -replace "ret(?=\.axcloud\.dynamics\.com)", "aos"
$cert = Get-ChildItem -Path Cert:\LocalMachine\My | 
    Where-Object { $_.Subject -like "*$certName*" } | 
    Sort-Object NotAfter -Descending | 
    Select-Object -First 1

if ($null -eq $cert) {
    Write-Error "No se encontró ningún certificado en Cert:\LocalMachine\My que coincida con '$certName'."
    exit 1
}

# Definir bloque de script reutilizable para aplicar el certificado SSL de manera compatible
# (Resuelve el problema de los métodos faltantes en objetos deserializados de PS7+ y fuerza SNI)
function Set-IISBindingWithCertificate {
    param (
        [string]$Site,
        [string]$HostHeader,
        [int]$Port,
        [string]$Thumbprint,
        [int]$SslFlags = 1 # 1 = Habilitar SNI para evitar conflictos con AOSService
    )

    $iisAction = {
        param($sName, $hHeader, $p, $tPrint, $sFlags)
        Import-Module WebAdministration -WarningAction SilentlyContinue
        
        # Verificar si el enlace ya existe, si no, crearlo con SNI
        $binding = Get-WebBinding -Name $sName -Protocol https -Port $p -HostHeader $hHeader | Select-Object -First 1
        if ($null -eq $binding) {
            # Se usa -SslFlags 1 para habilitar SNI en IIS
            New-WebBinding -Name $sName -IPAddress "*" -Port $p -HostHeader $hHeader -Protocol https -SslFlags $sFlags
            $binding = Get-WebBinding -Name $sName -Protocol https -Port $p -HostHeader $hHeader | Select-Object -First 1
        }
        
        # Asignar certificado
        if ($binding) {
            $binding.AddSslCertificate($tPrint, "My")
        } else {
            Write-Error "No se pudo obtener el binding creado para el sitio $sName en el puerto $p con host $hHeader."
        }
    }

    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # Si corre en PowerShell Core (7.4+), delegamos a Windows PowerShell nativo
        powershell.exe -NoProfile -NonInteractive -Command $iisAction -args $Site, $HostHeader, $Port, $Thumbprint, $SslFlags
    } else {
        # Si corre en PowerShell 5.1, se ejecuta directamente
        & $iisAction $Site $HostHeader $Port $Thumbprint $SslFlags
    }
}

# 1. Cambiar el puerto del RetailServer para liberar el puerto 443 si está ocupado
$RetailServer = "RetailServer"
$binding = Get-WebBinding -Name $RetailServer | Where-Object { $_.bindingInformation -like "*:${newPort}:*" }

if ($binding) {
    $dummyPort = 444
    $bindingInfo = $binding.BindingInformation
    $protocol = $binding.Protocol

    # Remover enlace conflictivo
    Remove-WebBinding -Name $RetailServer -BindingInformation $bindingInfo -Protocol $protocol

    # Crear nuevo enlace en puerto alternativo y aplicar certificado de forma compatible (usando SNI)
    Set-IISBindingWithCertificate -Site $RetailServer -HostHeader $newHostname -Port $dummyPort -Thumbprint $cert.Thumbprint -SslFlags 1
    
    Write-Host "El puerto del binding ha sido cambiado de $newPort a $dummyPort para el sitio $RetailServer." -ForegroundColor Green
} else {
    Write-Host "No se encontró un binding con el puerto $newPort en el sitio $RetailServer." -ForegroundColor Yellow
}

# 2. Configurar el sitio de Store Scale Unit ($siteName)
$site = Get-Website | Where-Object { $_.Name -eq $siteName }
if ($null -eq $site) {
    Write-Error "El sitio web '$siteName' no existe."
    exit 1
}

# Obtener y eliminar todos los enlaces actuales de la web CSU
$bindings = Get-WebBinding -Name $siteName
foreach ($b in $bindings) {
    Remove-WebBinding -Name $siteName -BindingInformation $b.BindingInformation -Protocol $b.Protocol
}

# Crear nuevo enlace y ASIGNAR el certificado correctamente con SNI
Set-IISBindingWithCertificate -Site $siteName -HostHeader $newHostname -Port $newPort -Thumbprint $cert.Thumbprint -SslFlags 1
Write-Host "Sitio $siteName configurado exitosamente en puerto $newPort con el host $newHostname y certificado SSL (SNI)." -ForegroundColor Green
