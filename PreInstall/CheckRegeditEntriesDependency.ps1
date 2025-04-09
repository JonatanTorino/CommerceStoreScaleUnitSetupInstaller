
. .\Support\SupportFunctions.ps1
PrintFileName $MyInvocation.MyCommand.Name

#Write Key Value
function WriteRegEditKeyValue {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$RegPath,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$RegKey,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$RegValue,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$RegType
    )

    # Create the path if it does not exist
    If (-NOT (Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
        Write-Host -ForegroundColor Green "New-Item -Path $RegPath -Force | Out-Null"
    }

    # Create the key if it does not exist
    If (-NOT (Test-RegistryValue $RegPath -Value $RegKey)) {
        New-ItemProperty -Path $RegPath -Name $RegKey -Value $RegValue -PropertyType $RegType -Force 
        Write-Host -ForegroundColor Green "New-ItemProperty -Path $RegPath -Name $RegKey -Value $RegValue -PropertyType $RegType -Force"
    }
    else {
        Set-ItemProperty -Path $RegPath -Name $RegKey -Value $RegValue -Force 
        Write-Host -ForegroundColor Yellow "Set-ItemProperty -Path $RegPath -Name $RegKey -Value $RegValue -PropertyType $RegType -Force"
    }
}

function Test-RegistryValue {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Path,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Value
    )

    try {

        Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

#--------------------------------------#
$Type = "DWORD" #Para todos igual

$RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'
$Name = 'Enabled'
$Value = '1'
WriteRegEditKeyValue $RegistryPath $Name $Value $Type
#--------------------------------------#

$RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server'
$Name = 'Enabled'
$Value = '1'
WriteRegEditKeyValue $RegistryPath $Name $Value $Type
#--------------------------------------#

#Se crean dos entradas en la misma ruta
$RegistryPath = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727'
$Name = 'SystemDefaultTlsVersions'
$Value = '1'
WriteRegEditKeyValue $RegistryPath $Name $Value $Type

$Name = 'SchUseStrongCrypto'
WriteRegEditKeyValue $RegistryPath $Name $Value $Type
#--------------------------------------#

#Se crean dos entradas en la misma ruta
$RegistryPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727'
$Name = 'SystemDefaultTlsVersions'
$Value = '1'
WriteRegEditKeyValue $RegistryPath $Name $Value $Type

$Name = 'SchUseStrongCrypto'
WriteRegEditKeyValue $RegistryPath $Name $Value $Type
#--------------------------------------#
