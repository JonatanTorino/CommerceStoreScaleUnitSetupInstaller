[CmdletBinding()]
param (
    [string]$jsonFile
)

$ErrorActionPreference = 'Stop'
$scriptRoot = $PSScriptRoot
$supportFunctionsPath = Join-Path -Path $scriptRoot -ChildPath '..\Support\SupportFunctions.ps1'
. $supportFunctionsPath

function Get-RequiredConfigurationValue {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [AllowNull()]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [int]$MaximumLength
    )

    $value = Assert-NotNullOrWhiteSpace -Name $Name -Value $Value
    if ($value.Length -gt $MaximumLength) {
        throw "El parámetro de configuración '$Name' supera la longitud máxima de $MaximumLength caracteres."
    }

    return $value
}

function Get-RequiredHttpUrl {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [AllowNull()]
        [string]$Value
    )

    $value = Get-RequiredConfigurationValue -Name $Name -Value $Value -MaximumLength 2046
    if (-not (Test-HttpUrl -Value $value)) {
        throw "El parámetro de configuración '$Name' debe ser una URL HTTP o HTTPS sin barra final."
    }

    return $value
}

function Get-ChannelConfigValue {
    param (
        [Parameter(Mandatory = $true)]
        [xml]$ConfigXml,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $value = Get-XmlAppSettingValue -ConfigXml $ConfigXml -Key $Key
    return Get-RequiredConfigurationValue -Name $Name -Value $value -MaximumLength 255
}

function ConvertTo-SqlLiteral {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "N'" + $Value.Replace("'", "''") + "'"
}

function Invoke-SqlCmdScript {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Server,

        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string[]]$Variables
    )

    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        throw "El script SQL no existe: $ScriptPath"
    }

    $rawVariableMap = @{}
    $variableDefinitions = @()
    foreach ($variable in $Variables) {
        $separator = $variable.IndexOf('=')
        if ($separator -le 0) {
            throw "La variable SQL no tiene el formato nombre=valor: $variable"
        }

        $name = $variable.Substring(0, $separator)
        $value = $variable.Substring($separator + 1)
        $rawVariableMap[$name] = $value
        $variableDefinitions += "$name=$($value.Replace("'", "''"))"
    }

    $invokeSqlcmd = Get-Command -Name Invoke-Sqlcmd -ErrorAction SilentlyContinue
    if ($null -ne $invokeSqlcmd) {
        $invokeParameters = @{
            ServerInstance = $Server
            Database = 'AxDB'
            InputFile = $ScriptPath
            Variable = $variableDefinitions
            AbortOnError = $true
            ErrorAction = 'Stop'
        }
        if ($invokeSqlcmd.Parameters.ContainsKey('Encrypt')) {
            $invokeParameters.Encrypt = 'Optional'
        }
        if ($invokeSqlcmd.Parameters.ContainsKey('TrustServerCertificate')) {
            $invokeParameters.TrustServerCertificate = $true
        }

        Invoke-Sqlcmd @invokeParameters
        return
    }

    $sqlcmd = Get-Command -Name sqlcmd.exe -CommandType Application -ErrorAction Stop
    $sql = Get-Content -LiteralPath $ScriptPath -Raw -ErrorAction Stop
    foreach ($name in $rawVariableMap.Keys) {
        $literal = ConvertTo-SqlLiteral -Value $rawVariableMap[$name]
        $sql = $sql.Replace("N'$($name)'", $literal).Replace('$(' + $name + ')', $rawVariableMap[$name].Replace("'", "''"))
    }

    $temporaryScript = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -LiteralPath $temporaryScript -Value $sql -Encoding UTF8
        & $sqlcmd.Source -S $Server -E -b -i $temporaryScript
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "sqlcmd.exe falló para '$ScriptPath' con código de salida $exitCode."
        }
    }
    finally {
        Remove-Item -LiteralPath $temporaryScript -Force -ErrorAction SilentlyContinue
    }
}

try {
    Write-Host
    Write-Host "========================================"
    Write-Host "     Inserting in AxDB the AadClientIds and Commerce Profile"
    Write-Host "========================================"
    Write-Host

    $jsonFile = GetJsonConfig -jsonFile $jsonFile -Suffix 'CSU'
    $csu = . Get-CSUParameters -jsonFile $jsonFile

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

    [xml]$channelConfigXml = Get-Content -LiteralPath $channelConfigPath -Raw -ErrorAction Stop
    $tenantId = Get-ChannelConfigValue -ConfigXml $channelConfigXml -Name 'TenantId' -Key 'TenantId'
    $storeSystemChannelDatabaseId = Get-ChannelConfigValue -ConfigXml $channelConfigXml -Name 'StoreSystemChannelDatabaseId' -Key 'StoreSystemChannelDatabaseId'

    $retailServerAadClientId = Get-RequiredConfigurationValue -Name 'RetailServerAadClientId' -Value $csu.RetailServerAadClientId -MaximumLength 38
    $cposAadClientId = Get-RequiredConfigurationValue -Name 'CposAadClientId' -Value $csu.CposAadClientId -MaximumLength 38
    $asyncClientAadClientId = Get-RequiredConfigurationValue -Name 'AsyncClientAadClientId' -Value $csu.AsyncClientAadClientId -MaximumLength 38
    $retailServerURL = Get-RequiredHttpUrl -Name 'RetailServerURL' -Value $csu.RetailServerURL
    $cposURL = Get-RequiredHttpUrl -Name 'CPOSUrl' -Value $csu.CPOSUrl
    $server = Assert-NotNullOrWhiteSpace -Name 'COMPUTERNAME' -Value $env:COMPUTERNAME

    $azureScriptPath = Join-Path -Path $scriptRoot -ChildPath 'InsertCmmSDKAzureActiveClientId.sql'
    $profileScriptPath = Join-Path -Path $scriptRoot -ChildPath 'InsertCmmSDKProfileConfig.sql'

    $azureVariables = @(
        ('AadPOSId=' + $cposAadClientId),
        ('AadRetailServerId=' + $retailServerAadClientId),
        ('AadAsyncClientId=' + $asyncClientAadClientId),
        ('TenantId=' + $tenantId),
        ('StoreSystemChannelDatabaseId=' + $storeSystemChannelDatabaseId),
        ('RetailServerURL=' + $retailServerURL),
        ('CPOSURL=' + $cposURL)
    )

    $profileVariables = @(
        ('StoreSystemChannelDatabaseId=' + $storeSystemChannelDatabaseId),
        ('RetailServerURL=' + $retailServerURL),
        ('CPOSURL=' + $cposURL)
    )

    Write-Host "Configuration file: $jsonFile"
    Write-Host "Channel configuration: $channelConfigPath"
    Write-Host "SQL Server: $server"

    Invoke-SqlCmdScript -Server $server -ScriptPath $azureScriptPath -Variables $azureVariables
    Invoke-SqlCmdScript -Server $server -ScriptPath $profileScriptPath -Variables $profileVariables
}
catch {
    Write-Error "Error al insertar la configuración de Commerce SDK en AxDB: $($_.Exception.Message)"
    throw
}
