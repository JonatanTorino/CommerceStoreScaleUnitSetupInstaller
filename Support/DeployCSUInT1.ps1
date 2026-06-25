#Requires -Version 5.0
param (
    [string]$AIOPPATH,
    [string]$PKGSPATH
)

# Solicitar AIOPPATH si no se asignó
if (-not $AIOPPATH) {
    $AIOPPATH = Read-Host "Ingrese carpeta AIOP o el archivo zip"
}

# Actualizar el propio repositorio CommerceStoreScaleUnitSetupInstaller
$installerRepo = Split-Path -Parent $MyInvocation.MyCommand.Path
$installerRepoRoot = Split-Path -Parent $installerRepo
Write-Host "Actualizando $installerRepoRoot ..."
Push-Location $installerRepoRoot
git fetch
git pull
Pop-Location

# Solicitar PKGSPATH si no se asignó
if (-not $PKGSPATH) {
    $PKGSPATH = Read-Host "Ingrese la ruta de destino para los archivos .nupkg (o presione ENTER para omitir este paso)"
}

. "$installerRepo\SupportFunctions.ps1"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Si la ruta es un zip, extraer a temporal
$tempFolder = $null
if ($AIOPPATH.ToLower().EndsWith(".zip") -and (Test-Path $AIOPPATH)) {
    $tempFolder = Join-Path $env:TEMP ("AIOP_" + [guid]::NewGuid().ToString())
    Expand-Archive -Path $AIOPPATH -DestinationPath $tempFolder -Force
    $AIOPBase = $tempFolder
} elseif (Test-Path $AIOPPATH) {
    $AIOPBase = $AIOPPATH
} else {
    Write-Host -ForegroundColor Red "Path is invalid"
    exit
}

$InstallersFoldersPath = Join-Path $AIOPBase "ExtensionsPackageInstallers"
$ExtFolder = Join-Path $AIOPBase "ext"

Stop-WebAppPoolForce -Name RssuCore
Stop-WebAppPoolForce -Name RetailServer

try {
    # Listas para almacenar los resultados
    $filesCompletedSuccessfully = @()
    $filesCompletedWithError = @()

    $InstallOrUninstall = "install"

    if (Test-Path $InstallersFoldersPath) {
        Get-ChildItem -Path $InstallersFoldersPath -Filter *.exe -Recurse | ForEach-Object {
            Invoke-InstallerWithTracking -InstallerPath $_.FullName -Action $InstallOrUninstall `
                -CompletedSuccessfully ([ref]$filesCompletedSuccessfully) `
                -CompletedWithError ([ref]$filesCompletedWithError)
        }
    } else {
        Write-Host "No se encontró la carpeta ExtensionsPackageInstallers en $InstallersFoldersPath"
    }

    Show-InstallerSummary -CompletedSuccessfully $filesCompletedSuccessfully -CompletedWithError $filesCompletedWithError

    $destinationPath = "C:\Program Files\Microsoft Dynamics 365\10.0\Commerce Scale Unit\Extensions\ext"
    if (Test-Path $destinationPath) {
        Remove-Item -Path $destinationPath -Recurse -Force
        Write-Host "Existing 'ext' folder deleted."
    } else {
        Write-Host "No existing 'ext' folder found."
    }

    if (Test-Path $ExtFolder) {
        Copy-Item -Path $ExtFolder -Destination $destinationPath -Recurse
        Write-Host "New 'ext' folder copied from '$ExtFolder' to '$destinationPath'."

        $oldConfig = Join-Path $destinationPath "CommerceRuntime.ext.config"
        if (Test-Path $oldConfig) {
            Rename-Item -Path $oldConfig -NewName "Extension.config" -Force
            Write-Host "Archivo 'CommerceRuntime.ext.config' renombrado a 'Extension.config'."
        } else {
            Write-Host "El archivo 'CommerceRuntime.ext.config' no se encontró para renombrar."
        }
    } else {
        Write-Host "Source path '$ExtFolder' does not exist. Please check the path."
    }

    $parentPath = "C:\Program Files\Microsoft Dynamics 365\10.0\Commerce Scale Unit\Extensions"
    Get-ChildItem -Path $parentPath -Directory | Where-Object { $_.Name -ne "ext" } | ForEach-Object {
        Remove-Item -Path $_.FullName -Recurse -Force
        Write-Host "Carpeta '$($_.Name)' eliminada."
    }
    Write-Host "Proceso completado. Solo la carpeta 'ext' permanece."

    # --- BLOQUE OPCIONAL PARA COPIAR LOS .nupkg ---
    if ($PKGSPATH -and $PKGSPATH.Trim() -ne "") {
        $PkgsSource = Join-Path $AIOPBase "pkgsIP"
        if (Test-Path $PkgsSource) {
            if (-not (Test-Path $PKGSPATH)) {
                New-Item -Path $PKGSPATH -ItemType Directory | Out-Null
            }
            Get-ChildItem -Path $PkgsSource -Filter *.nupkg | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $PKGSPATH -Force
                Write-Host "Archivo '$($_.Name)' copiado a '$PKGSPATH'."
            }
            Write-Host "Todos los archivos .nupkg fueron copiados a '$PKGSPATH'."
        } else {
            Write-Host -ForegroundColor Yellow "No se encontró la carpeta 'pkgs' en la ruta de origen."
        }
    } else {
        Write-Host "No se especificó ruta de destino para los paquetes .nupkg. Este paso se omite."
    }
} finally {
    Write-Host
    Write-Host
    Start-WebAppPool -Name RssuCore
    Start-WebAppPool -Name RetailServer
    Write-Host
    Write-Host
}

# Limpiar temporal si se extrajo zip
if ($tempFolder) {
    Remove-Item -Path $tempFolder -Recurse -Force
}

$elapsedSecods = $stopwatch.Elapsed
Write-Host -ForegroundColor Green 'Total elapsed time: '
$elapsedSecods
$stopwatch.Stop()