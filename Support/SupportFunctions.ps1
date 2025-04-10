# SupportFunctions.ps1
# Descripción: Módulo con funciones de soporte reutilizables

# Definir información del módulo
# $ModuleVersion = "1.0.1"
# $Author = "Jonatan Torino"

function Get-OSInfo {
    # Determinar si es un sistema operativo de servidor o cliente
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $isServerOS = $osInfo.ProductType -ne 1 # 1 = Workstation, 2 = Domain Controller, 3 = Member Server
    return $isServerOS
}

# Assign the result of Get-OSInfo to $isServerOS (consolidated)
$isServerOS = Get-OSInfo

if ($isServerOS) {
    # En Windows Server, usar el módulo WebAdministration
    if (Get-Module -ListAvailable -Name WebAdministration) {
        Import-Module WebAdministration
    } else {
        Write-Host -ForegroundColor Yellow "El módulo WebAdministration no está disponible. Algunas funciones pueden no estar operativas."
    }
} else {
    # En Windows Cliente, usar el módulo IISAdministration si está disponible
    if (Get-Module -ListAvailable -Name IISAdministration) {
        Import-Module IISAdministration
    } else {
        Write-Host -ForegroundColor Yellow "El módulo IISAdministration no está disponible. Algunas funciones pueden no estar operativas."
    }
}

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

function GetAosServiceUrl {
    [string]$webSite = "AOSService"
    
    # Obtiene la información del sitio web
    $sitio = Get-WebSite -Name $webSite

    # Obtiene el binding principal
    $bindings = $sitio.bindings
    $binding = $bindings.Collection | Where-Object { $_.bindingInformation -match "aos\." } | Select-Object -First 1
    
    # Usar una expresión regular para extraer el host y el puerto
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

function PrintFileName {
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

function GetLocalHostNameCertificateThumbprint {
    # Obtener el nombre del host local
    $localHostName = $env:COMPUTERNAME  # o [System.Net.Dns]::GetHostName()
    Write-Host -ForegroundColor Green "Nombre del host local: $localHostName"
    
    # Obtener el certificado utilizando el nombre amigable
    $localhostCertThumbprint = GetCertificateThumbprint -friendlyName $localHostName
    
    if ($null -ne $localhostCertThumbprint) {
        Write-Host -ForegroundColor Green "Certificado '$localHostName' encontrado o creado: $localhostCertThumbprint"
        return $localhostCertThumbprint
    } else {
        Write-Host -ForegroundColor Red "No se pudo obtener o crear un certificado para '$localHostName'."
        return $null
    }
}

function GetCertificateThumbprint {
    param (
        [string]$friendlyName
    )

    $cert = GetCertificate -friendlyName $friendlyName

    # Buscar un certificado con el Friendly Name especificado
    $cert = $cert | Where-Object { $_.FriendlyName -eq $friendlyName } | Select-Object -First 1
    return $cert.Thumbprint
}

function GetCertificate {
    param (
        [string]$friendlyName
    )
    
    # Buscar un certificado con el Friendly Name especificado
    $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.FriendlyName -eq $friendlyName }
        
    if ($null -ne $cert) {
        Write-Host -ForegroundColor Green "Certificado '$friendlyName' encontrado: $($cert.Thumbprint)"
    } else {
        Write-Host -ForegroundColor Red "Certificado con el Friendly Name '$friendlyName' no encontrado."
        CreateNewCertificate -friendlyName $friendlyName

        $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.FriendlyName -eq $friendlyName } 
                
        if ($null -ne $cert) {
            Write-Host -ForegroundColor Green "Certificado '$friendlyName' creado: $($cert.Thumbprint)"
        } else {
            Write-Host -ForegroundColor Red "Error al crear el certificado '$friendlyName'."
        }
    }

    return $cert
}

function CreateNewCertificate {
    param (
        [string]$friendlyName
    )
    
    Write-Host -ForegroundColor Yellow "Creando un nuevo certificado autofirmado para '$friendlyName'."
        
    # Crear un nuevo certificado autofirmado con Key Usage y Extended Key Usage
    $certNew = New-SelfSignedCertificate -DnsName $friendlyName `
        -CertStoreLocation Cert:\LocalMachine\My `
        -KeyLength 2048 `
        -NotAfter (Get-Date).AddYears(5) `
        -FriendlyName $friendlyName `
        -KeyUsage DigitalSignature, KeyEncipherment, DataEncipherment `
        -KeyExportPolicy Exportable `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1") # Extended Key Usage: Server Authentication

    # Importar el certificado al almacén de Trusted Root Certification Authorities
    $rootStore = "Cert:\LocalMachine\Root"
    Write-Host -ForegroundColor Yellow "Importando el certificado al almacén de Trusted Root Certification Authorities."
    $certNew | Export-Certificate -FilePath "$env:TEMP\$friendlyName.cer" -Force
    Import-Certificate -FilePath "$env:TEMP\$friendlyName.cer" -CertStoreLocation $rootStore
    Remove-Item -Path "$env:TEMP\$friendlyName.cer" -Force
}

function GetJsonConfig {
    param (
        [string]$jsonFile
    )

    # Comprobar si el parámetro no fue pasado o el archivo no existe
    if ([string]::IsNullOrEmpty($jsonFile) -or -not (Test-Path -Path $jsonFile -PathType Leaf)) {
        $nombreEntorno = [System.Environment]::MachineName
        $ConfigFiles = '.\ConfigFiles\'
        $rutaArchivoEntorno = $ConfigFiles + $nombreEntorno + ".json"
        $jsonFileDefault = Get-ChildItem -Path $ConfigFiles -Filter "$nombreEntorno.json" | Select-Object -ExpandProperty FullName
        Write-Host -ForegroundColor Yellow "Script invocado sin especificar ruta de archivo de configuración JSON."
        Write-Host -ForegroundColor Yellow "Por lo tanto se busca por defecto el siguiente archivo:"
        Write-Host "   $rutaArchivoEntorno"

        if (($null -ne $jsonFileDefault) -and (Test-Path $jsonFileDefault -PathType Any)) {
            Write-Host -ForegroundColor Green "ARCHIVO ENCONTRADO"
        } else {
            Write-Host -ForegroundColor Red "Archivo no encontrado: $rutaArchivoEntorno"
            throw [System.IO.FileNotFoundException] "$rutaArchivoEntorno not found."
        }

        $jsonFile = $jsonFileDefault
    }

    return $jsonFile
}

function ExistsAosServiceFolder {
    $exists = $false
    $folderName = "AosService"

    if (Test-Path Env:SERVICEDRIVE) {
        $serviceDrivePath = $env:SERVICEDRIVE
        $targetFolderPath = Join-Path -Path $serviceDrivePath -ChildPath $folderName
        if (Test-Path -Path $targetFolderPath -PathType Container) {
            $exists = $true
        } 
    }
    return $exists
}

function HasInstalledIIS {
    $isServerOS = Get-OSInfo

    $iisInstalled = $false

    if ($isServerOS) {
        # En Windows Server, usar Get-WindowsFeature
        try {
            # El módulo ServerManager puede no estar cargado por defecto en algunas sesiones
            Import-Module ServerManager -ErrorAction SilentlyContinue
            $iisFeature = Get-WindowsFeature -Name Web-Server -ErrorAction SilentlyContinue
            if ($null -ne $iisFeature -and $iisFeature.Installed) {
                $iisInstalled = $true
            }
        } catch {
            Write-Warning "No se pudo usar Get-WindowsFeature. Error: $($_.Exception.Message)"
            # Intenta un método alternativo si Get-WindowsFeature falla (menos común)
            # Podrías intentar Get-WindowsOptionalFeature aquí también como fallback,
            # aunque es menos probable que funcione si Get-WindowsFeature falló.
        }
    } else {
        # En Windows Cliente (10/11), usar Get-WindowsOptionalFeature
        try {
            $iisFeature = Get-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -ErrorAction SilentlyContinue
            if ($null -ne $iisFeature -and $iisFeature.State -eq [Microsoft.Dism.Commands.FeatureState]::Enabled) {
                $iisInstalled = $true
            }
        } catch {
            Write-Warning "No se pudo usar Get-WindowsOptionalFeature. Error: $($_.Exception.Message)"
        }
    }

    return $iisInstalled
}

function New-LocalConfigFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComponentSuffix
    )

    $sampleFileNameBase = "SAMPLE_Config_By_Env_(DuplicateAndRename)"

    $hostname = $env:COMPUTERNAME
    $configFolder = ".\ConfigFiles"
    $configFile = "$hostname.$ComponentSuffix"
    $jsonFile = "$configFolder\$configFile.json"
    $jsonBackupFile = $null
    
    # Creo una copia de backup de existir una versión actual
    $fileCount = (Get-ChildItem -Path $configFolder -Filter "$configFile*" -File | Measure-Object).Count
    if ($fileCount -gt 0) {
        $jsonBackupFile = "$configFolder\$configFile.BK$fileCount.json"
        Rename-Item $jsonFile -NewName $jsonBackupFile
    }

    # Copy the sample file to the target file path
    Copy-Item -LiteralPath "$configFolder\$sampleFileNameBase.$ComponentSuffix.json" -Destination $jsonFile -Force

    # Return both the new config file and backup file paths (if any)
    return [PSCustomObject]@{
        ConfigFile = $jsonFile
        BackupFile = $jsonBackupFile
    }
}