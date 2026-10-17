[CmdletBinding()]
param (
    [string]
    [ValidateNotNullOrEmpty()]
    $jsonFile
)

$ErrorActionPreference = 'Stop'
. (Join-Path -Path $PSScriptRoot -ChildPath '..\Support\SupportFunctions.ps1')

if (-not (Test-Path -LiteralPath $jsonFile -PathType Leaf)) {
    throw [System.IO.FileNotFoundException] "$jsonFile not found."
}

$jsonFile = (Resolve-Path -LiteralPath $jsonFile).Path
$csu = . Get-CSUParameters -jsonFile $jsonFile

$configurationChecks = @(
    [PSCustomObject]@{ Name = 'RetailServerURL'; Value = $csu.RetailServerURL; MaximumLength = 2046; IsUrl = $true },
    [PSCustomObject]@{ Name = 'CPOSUrl'; Value = $csu.CPOSUrl; MaximumLength = 2046; IsUrl = $true },
    [PSCustomObject]@{ Name = 'RetailServerAadClientId'; Value = $csu.RetailServerAadClientId; MaximumLength = 38; IsUrl = $false },
    [PSCustomObject]@{ Name = 'CposAadClientId'; Value = $csu.CposAadClientId; MaximumLength = 38; IsUrl = $false },
    [PSCustomObject]@{ Name = 'AsyncClientAadClientId'; Value = $csu.AsyncClientAadClientId; MaximumLength = 38; IsUrl = $false },
    [PSCustomObject]@{ Name = 'EnvironmentId'; Value = $csu.EnvironmentId; MaximumLength = 255; IsUrl = $false }
)

foreach ($configurationCheck in $configurationChecks) {
    $value = Assert-NotNullOrWhiteSpace -Name $configurationCheck.Name -Value $configurationCheck.Value
    if ($value.Length -gt $configurationCheck.MaximumLength) {
        throw "El parámetro de configuración '$($configurationCheck.Name)' supera la longitud máxima de $($configurationCheck.MaximumLength) caracteres."
    }
    if ($configurationCheck.IsUrl -and -not (Test-HttpUrl -Value $value)) {
        throw "El parámetro de configuración '$($configurationCheck.Name)' debe ser una URL HTTP o HTTPS sin barra final."
    }
}

$channelConfigPath = $null
if (-not [string]::IsNullOrWhiteSpace($csu.ChannelConfig)) {
    if (Test-Path -LiteralPath $csu.ChannelConfig -PathType Leaf) {
        $channelConfigPath = (Resolve-Path -LiteralPath $csu.ChannelConfig).Path
    }
    else {
        $candidatePaths = @(
            (Join-Path -Path (Split-Path -Parent $jsonFile) -ChildPath $csu.ChannelConfig),
            (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath $csu.ChannelConfig)
        )
        foreach ($candidatePath in $candidatePaths) {
            if (Test-Path -LiteralPath $candidatePath -PathType Leaf) {
                $channelConfigPath = (Resolve-Path -LiteralPath $candidatePath).Path
                break
            }
        }
    }
}

if ([string]::IsNullOrWhiteSpace($channelConfigPath)) {
    throw "El archivo ChannelConfig no existe o no está configurado."
}

try {
    [xml]$channelConfigXml = Get-Content -LiteralPath $channelConfigPath -Raw -ErrorAction Stop
}
catch {
    throw "No se pudo cargar el archivo ChannelConfig '$channelConfigPath': $($_.Exception.Message)"
}

$appInsightsKeys = @(
    'AsyncClientAppInsightsInstrumentationKey',
    'CloudPosAppInsightsInstrumentationKey',
    'RetailServerAppInsightsInstrumentationKey'
)

foreach ($appInsightsKey in $appInsightsKeys) {
    $value = Get-XmlAppSettingValue -ConfigXml $channelConfigXml -Key $appInsightsKey
    Assert-NotNullOrWhiteSpace -Name $appInsightsKey -Value $value | Out-Null
}

$environmentIdJson = Assert-NotNullOrWhiteSpace -Name 'EnvironmentId' -Value $csu.EnvironmentId
$environmentIdXmlValue = Get-XmlAppSettingValue -ConfigXml $channelConfigXml -Key 'EnvironmentId'
$environmentIdXml = Assert-NotNullOrWhiteSpace -Name 'ChannelConfig EnvironmentId' -Value $environmentIdXmlValue

if ($environmentIdJson -ne $environmentIdXml) {
    throw "El archivo $channelConfigPath tiene un EnvironmentId diferente al del $jsonFile."
}

Assert-NotNullOrWhiteSpace -Name 'TenantId' -Value (Get-XmlAppSettingValue -ConfigXml $channelConfigXml -Key 'TenantId') | Out-Null
Assert-NotNullOrWhiteSpace -Name 'StoreSystemChannelDatabaseId' -Value (Get-XmlAppSettingValue -ConfigXml $channelConfigXml -Key 'StoreSystemChannelDatabaseId') | Out-Null
