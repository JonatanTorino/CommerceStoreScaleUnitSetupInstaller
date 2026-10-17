#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Mueve el binding 443 del sitio RetailServer al puerto 444 y deja el sitio
    RetailStoreScaleUnitWebSite.AspNetCore escuchando en 443 con el mismo certificado.

.NOTES
    Los bindings HTTPS sin SNI (sslFlags = 0) de todos los sitios que usan *:443
    (AOSService, RetailCloudPos, RetailServer, CSU) comparten UNA sola entrada en
    HTTP.sys: 0.0.0.0:443. Remove-WebBinding borra esa entrada compartida, por lo que
    AOSService pierde el certificado. Por eso este script:
      1. Captura el thumbprint ANTES de tocar nada.
      2. Gestiona los certificados de HTTP.sys con netsh (mismo comportamiento en
         PowerShell 5.1 y 7+; en 7+ WebAdministration corre en una sesión de
         compatibilidad y sus objetos no exponen AddSslCertificate()).
      3. Restaura siempre (finally) la entrada 0.0.0.0:443.
#>

param (
    [parameter(Mandatory = $true
        , HelpMessage = "Ingresar URL del RetailServer")
    ]
    [string]
    [ValidateNotNullOrEmpty()]$retailServerURL
)

. (Join-Path -Path $PSScriptRoot -ChildPath '..\Support\SupportFunctions.ps1')
PrintFileName $MyInvocation.MyCommand.Name

Import-Module WebAdministration -ErrorAction Stop -WarningAction SilentlyContinue

# AppId que usa IIS para registrar certificados en HTTP.sys
$iisAppId = '{4dc3e181-e14b-4a21-b022-59fc669b0914}'

function Get-SslEndpoint {
    # Traduce un binding de IIS a su entrada en HTTP.sys (ipport o hostnameport)
    param (
        [Parameter(Mandatory = $true)][string]$BindingInformation,
        [int]$SslFlags = 0
    )

    if ($BindingInformation -notmatch '^(?<ip>.*):(?<port>\d+):(?<host>[^:]*)$') {
        throw "bindingInformation inválido: $BindingInformation"
    }

    if (($SslFlags -band 1) -and $Matches.host) {
        return [PSCustomObject]@{ Kind = 'hostnameport'; Value = "$($Matches.host):$($Matches.port)" }
    }

    $ip = if ($Matches.ip -in @('*', '')) { '0.0.0.0' } else { $Matches.ip }
    return [PSCustomObject]@{ Kind = 'ipport'; Value = "${ip}:$($Matches.port)" }
}

function Get-HttpSysCertificateHash {
    param ([Parameter(Mandatory = $true)]$Endpoint)

    $output = & netsh http show sslcert "$($Endpoint.Kind)=$($Endpoint.Value)" 2>&1 | Out-String
    # El único valor hexadecimal de 40 caracteres de la salida es el hash (independiente del idioma del SO)
    if ($LASTEXITCODE -eq 0 -and $output -match '\b(?<hash>[0-9a-fA-F]{40})\b') {
        return $Matches.hash.ToUpperInvariant()
    }
    return $null
}

function Set-HttpSysCertificate {
    param (
        [Parameter(Mandatory = $true)]$Endpoint,
        [Parameter(Mandatory = $true)][string]$Thumbprint
    )

    $current = Get-HttpSysCertificateHash -Endpoint $Endpoint
    if ($current -eq $Thumbprint) {
        Write-Host "Certificado $Thumbprint ya asignado a $($Endpoint.Value)."
        return
    }
    if ($current) {
        & netsh http delete sslcert "$($Endpoint.Kind)=$($Endpoint.Value)" | Out-Null
    }

    $output = & netsh http add sslcert "$($Endpoint.Kind)=$($Endpoint.Value)" "certhash=$Thumbprint" "appid=$iisAppId" "certstorename=MY" 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo asignar el certificado $Thumbprint a $($Endpoint.Value): $output"
    }
    Write-Host "Certificado $Thumbprint asignado a $($Endpoint.Value)." -ForegroundColor Green
}

function Find-CertificateThumbprint {
    # Último recurso: busca en el store el certificado del AOS a partir del hostname del RetailServer
    param ([Parameter(Mandatory = $true)][string]$Hostname)

    $certName = $Hostname -replace "ret(?=\.axcloud\.dynamics\.com)", "aos"
    $cert = Get-ChildItem -Path Cert:\LocalMachine\My |
        Where-Object { $_.Subject -like "*$certName*" -and $_.NotAfter -gt (Get-Date) } |
        Sort-Object -Property NotAfter -Descending |
        Select-Object -First 1
    if ($cert) { return $cert.Thumbprint.ToUpperInvariant() }
    return $null
}

$siteName = "RetailStoreScaleUnitWebSite.AspNetCore"
$retailServerSite = "RetailServer"
$newHostname = ([System.Uri]::new($retailServerURL)).Host
$newPort = 443
$dummyPort = 444
$sharedEndpoint = Get-SslEndpoint -BindingInformation "*:${newPort}:"

# No enumerar todos los sitios: en PS 7+ "Get-Website" sin -Name falla al deserializar
# "Default Web Site" (0x8007000D). Consultar solo el sitio necesario.
if ($null -eq (Get-Website -Name $siteName -ErrorAction SilentlyContinue)) {
    Write-Host "El sitio web $siteName no existe" -ForegroundColor Red
    return
}

# 1. Capturar el certificado antes de cualquier cambio
$retailBinding = @(Get-WebBinding -Name $retailServerSite -Protocol https |
        Where-Object { $_.bindingInformation -like "*:${newPort}:*" }) | Select-Object -First 1

$thumbprint = $null
if ($retailBinding) {
    # En PS 7+ el objeto llega deserializado desde la sesión de compatibilidad: no asumir el tipo de sslFlags
    $sslFlags = 0
    [void][int]::TryParse([string]$retailBinding.sslFlags, [ref]$sslFlags)
    $thumbprint = Get-HttpSysCertificateHash -Endpoint (Get-SslEndpoint -BindingInformation $retailBinding.bindingInformation -SslFlags $sslFlags)
    if (-not $thumbprint -and $retailBinding.certificateHash) {
        $thumbprint = ([string]$retailBinding.certificateHash).ToUpperInvariant()
    }
}
if (-not $thumbprint) { $thumbprint = Get-HttpSysCertificateHash -Endpoint $sharedEndpoint }
if (-not $thumbprint) { $thumbprint = Find-CertificateThumbprint -Hostname $newHostname }
if (-not $thumbprint) {
    throw "No se encontró el certificado a utilizar (binding de $retailServerSite, HTTP.sys $($sharedEndpoint.Value) ni store LocalMachine\My)."
}
Write-Host "Certificado a utilizar: $thumbprint"

try {
    # 2. Mover RetailServer de 443 a 444 para liberar el 443
    if ($retailBinding) {
        $retailHost = ($retailBinding.bindingInformation -split ':')[-1]
        if (-not $retailHost) { $retailHost = $newHostname }

        Remove-WebBinding -Name $retailServerSite -BindingInformation $retailBinding.bindingInformation -Protocol https -ErrorAction Stop

        $existsDummy = Get-WebBinding -Name $retailServerSite -Protocol https -Port $dummyPort -HostHeader $retailHost
        if (-not $existsDummy) {
            New-WebBinding -Name $retailServerSite -IPAddress "*" -Port $dummyPort -HostHeader $retailHost -Protocol https -ErrorAction Stop
        }
        Set-HttpSysCertificate -Endpoint (Get-SslEndpoint -BindingInformation "*:${dummyPort}:$retailHost") -Thumbprint $thumbprint

        Write-Host "El binding de $retailServerSite fue movido del puerto $newPort al $dummyPort."
    }
    else {
        Write-Host "No se encontró un binding con el puerto $newPort en el sitio $retailServerSite." -ForegroundColor Yellow
    }

    # 3. Reemplazar los bindings del sitio CSU por https *:443:<hostname>
    foreach ($binding in @(Get-WebBinding -Name $siteName)) {
        Remove-WebBinding -Name $siteName -BindingInformation $binding.bindingInformation -Protocol $binding.protocol -ErrorAction Stop
    }
    New-WebBinding -Name $siteName -IPAddress "*" -Port $newPort -HostHeader $newHostname -Protocol https -ErrorAction Stop
    Write-Host "Binding https *:${newPort}:$newHostname creado para $siteName."
}
finally {
    # 4. Remove-WebBinding borra la entrada compartida 0.0.0.0:443 (AOSService, RetailCloudPos, CSU): restaurarla
    Set-HttpSysCertificate -Endpoint $sharedEndpoint -Thumbprint $thumbprint
}
