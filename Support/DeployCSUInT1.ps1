param (
    [Parameter(Mandatory=$true)]
    [string]$AIOPPATH,

    [Parameter(Mandatory=$false)]
    [string]$PKGSPATH = $null
)

# --- Convertir string vacío a null ---
if ($PKGSPATH -eq "") {
    $PKGSPATH = $null
}

# --- Actualizar el propio repositorio ---
$installerRepo = Split-Path -Parent $MyInvocation.MyCommand.Path
$installerRepoRoot = Split-Path -Parent $installerRepo
Write-Host "Actualizando $installerRepoRoot ..."
Push-Location $installerRepoRoot
git fetch
git pull
Pop-Location

# --- Función de parada de AppPools ---
function Stop-WebAppPoolForce {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    try {
        Stop-WebAppPool -Name $Name -ErrorAction SilentlyContinue
        Write-Host "Operacion de detención completada para '$Name'"
    } catch {
        Write-Host "El AppPool '$Name' ya está detenido."
    }
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# --- Validar AIOPPATH ---
if (-not (Test-Path $AIOPPATH)) {
    Write-Host -ForegroundColor Red "Path $AIOPPATH no existe. Verificar pipeline."
    exit 1
}

# --- Si es zip, extraer a temporal ---
$tempFolder = $null
if ($AIOPPATH.ToLower().EndsWith(".zip")) {
    $tempFolder = Join-Path $env:TEMP ("AIOP_" + [guid]::NewGuid().ToString())
    Expand-Archive -Path $AIOPPATH -DestinationPath $tempFolder -Force
    $AIOPBase = $tempFolder
} else {
    $AIOPBase = $AIOPPATH
}

$InstallersFoldersPath = Join-Path $AIOPBase "ExtensionsPackageInstallers"
$ExtFolder = Join-Path $AIOPBase "ext"

# --- Detener AppPools ---
Stop-WebAppPoolForce -Name RssuCore
Stop-WebAppPoolForce -Name RetailServer

# --- Ejecutar instaladores ---
$archivosTerminadosCorrectamente = @()
$archivosTerminadosConError = @()
$InstallOrUninstall = "install"

if (Test-Path $InstallersFoldersPath) {
    Get-ChildItem -Path $InstallersFoldersPath -Filter *.exe -Recurse | ForEach-Object {
        $nombreArchivo = $_.Name
        Write-Host
        Write-Host
        Write-Host -ForegroundColor Green "$nombreArchivo | $InstallOrUninstall"

        $command = $_.Fullname + " $InstallOrUninstall"
        Invoke-Expression $command

        if ($LASTEXITCODE -eq 0) {
            Write-Host "$nombreArchivo terminó correctamente."
            $archivosTerminadosCorrectamente += $nombreArchivo
        } else {
            Write-Host "$nombreArchivo finalizó con un error. Código de salida: $LASTEXITCODE"
            $archivosTerminadosConError += $nombreArchivo
        }
    }
} else {
    Write-Host "No se encontró la carpeta ExtensionsPackageInstallers en $InstallersFoldersPath"
}

# --- Informe final ---
Write-Host
Write-Host "Archivos que terminaron correctamente:"
$archivosTerminadosCorrectamente
Write-Host
Write-Host "Archivos que terminaron con error:"
$archivosTerminadosConError

# --- Iniciar AppPools ---
Start-WebAppPool -Name RssuCore

# --- Copiar carpeta 'ext' ---
$destinationPath = "C:\Program Files\Microsoft Dynamics 365\10.0\Commerce Scale Unit\Extensions\ext"
if (Test-Path $destinationPath) {
    Remove-Item -Path $destinationPath -Recurse -Force
    Write-Host "Existing 'ext' folder deleted."
}

if (Test-Path $ExtFolder) {
    Copy-Item -Path $ExtFolder -Destination $destinationPath -Recurse
    Write-Host "New 'ext' folder copiada desde '$ExtFolder' a '$destinationPath'."

    $oldConfig = Join-Path $destinationPath "CommerceRuntime.ext.config"
    if (Test-Path $oldConfig) {
        Rename-Item -Path $oldConfig -NewName "Extension.config" -Force
        Write-Host "Archivo 'CommerceRuntime.ext.config' renombrado a 'Extension.config'."
    }
}

# --- Limpiar otras carpetas ---
$parentPath = "C:\Program Files\Microsoft Dynamics 365\10.0\Commerce Scale Unit\Extensions"
Get-ChildItem -Path $parentPath -Directory | Where-Object { $_.Name -ne "ext" } | ForEach-Object {
    Remove-Item -Path $_.FullName -Recurse -Force
    Write-Host "Carpeta '$($_.Name)' eliminada."
}
Write-Host "Proceso completado. Solo la carpeta 'ext' permanece."

# --- BLOQUE OPCIONAL PARA COPIAR LA CARPETA pkgsIP ---
if ($PKGSPATH) {
    $PkgsSource = Join-Path $AIOPBase "pkgsIP"
    $PkgsDest = Join-Path $PKGSPATH "pkgsIP"
    if (Test-Path $PkgsSource) {
        if (Test-Path $PkgsDest) {
            Remove-Item -Path $PkgsDest -Recurse -Force
            Write-Host "Carpeta existente 'pkgsIP' eliminada en '$PKGSPATH'."
        }
        Copy-Item -Path $PkgsSource -Destination $PKGSPATH -Recurse
        Write-Host "Carpeta 'pkgsIP' copiada desde '$PkgsSource' a '$PKGSPATH'."
    } else {
        Write-Host -ForegroundColor Yellow "No se encontró la carpeta 'pkgsIP' en la ruta de origen."
    }
} else {
    Write-Host "No se especificó ruta de destino para los paquetes .nupkg. Este paso se omite."
}

# --- Limpiar temporal ---
if ($tempFolder) {
    Remove-Item -Path $tempFolder -Recurse -Force
}

# --- Tiempo total ---
$elapsedSecods = $stopwatch.Elapsed
Write-Host -ForegroundColor Green "Total elapsed time: $elapsedSecods"
$stopwatch.Stop()
