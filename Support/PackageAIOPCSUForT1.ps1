param (
    [string]$RepoName
)

if (-not $RepoName) {
    $RepoName = Read-Host "Ingrese el nombre del repositorio"
}

# Actualizar el propio repositorio CommerceStoreScaleUnitSetupInstaller
$installerRepo = Split-Path -Parent $MyInvocation.MyCommand.Path
$installerRepoRoot = Split-Path -Parent $installerRepo
Write-Host "Actualizando $installerRepoRoot ..."
Push-Location $installerRepoRoot
git fetch
git pull
Pop-Location

# Hacer git pull en K:\Repos\IPRetailV2 sobre la rama dev
$repo1 = "K:\Repos\IPRetailV2"
Write-Host "Actualizando $repo1 ..."
Push-Location $repo1
git fetch
git checkout DEV
git pull origin DEV
Pop-Location

# Hacer git pull en el repositorio pasado por parámetro sobre la rama dev
$repo2 = "K:\Repos\$RepoName"
Write-Host "Actualizando $repo2 ..."
Push-Location $repo2
git fetch
git checkout dev
git pull origin dev
Pop-Location

# Ruta fija a MSBuild de Visual Studio 2022
$msbuildExe = "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"

# Ejecutar msbuild en K:\Repos\IPRetailV2\CmmSDK\src
$msbuildPath1 = "K:\Repos\IPRetailV2\CmmSDK\src"
Write-Host "Ejecutando msbuild en $msbuildPath1 ..."
Push-Location $msbuildPath1
& $msbuildExe
$exitCode1 = $LASTEXITCODE
Pop-Location
if ($exitCode1 -ne 0) {
    Write-Host "Error en msbuild en $msbuildPath1. Código de salida: $exitCode1"
    exit $exitCode1
}

# Ejecutar msbuild en K:\Repos\CarlosIsla\CmmSDK\src
$msbuildPath2 = "K:\Repos\CarlosIsla\CmmSDK\src"
Write-Host "Ejecutando msbuild en $msbuildPath2 ..."
Push-Location $msbuildPath2
& $msbuildExe
$exitCode2 = $LASTEXITCODE
Pop-Location
if ($exitCode2 -ne 0) {
    Write-Host "Error en msbuild en $msbuildPath2. Código de salida: $exitCode2"
    exit $exitCode2
}


# Construir rutas base
$basePath = "K:\Repos\$RepoName\CmmSDK"

# 1. Buscar el único .zip dentro de la ruta netstandard2.0
$zipFolder = Join-Path $basePath "src\MergedPackage\ScaleUnit\bin\Debug\netstandard2.0"
$zipPath = Get-ChildItem -Path $zipFolder -Filter *.zip | Select-Object -First 1 | ForEach-Object { $_.FullName }

# 3. Buscar la carpeta más reciente en ExtensionsPackageInstallers y tomar los .exe de allí
$installersRoot = Join-Path $basePath "ExtensionsPackageInstallers"
$latestInstallerFolder = Get-ChildItem -Path $installersRoot -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$installersPath = $null
if ($latestInstallerFolder) {
    $installersPath = $latestInstallerFolder.FullName
}

# Crear carpeta temporal
$tempFolder = Join-Path $env:TEMP ("AIOPCSU_" + [guid]::NewGuid().ToString())
New-Item -Path $tempFolder -ItemType Directory | Out-Null

# Extraer solo la carpeta ext del zip
$extTemp = Join-Path $tempFolder "ext"
Add-Type -AssemblyName System.IO.Compression.FileSystem
if ($zipPath -and (Test-Path $zipPath)) {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    foreach ($entry in $zip.Entries) {
        if ($entry.FullName -like "RetailServer/Code/bin/ext/*" -and -not $entry.FullName.EndsWith("/")) {
            $target = Join-Path $extTemp ($entry.FullName.Substring("RetailServer/Code/bin/ext/".Length))
            $targetDir = Split-Path $target
            if (-not (Test-Path $targetDir)) {
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
            }
            $entryStream = $entry.Open()
            $fileStream = [System.IO.File]::Create($target)
            $entryStream.CopyTo($fileStream)
            $fileStream.Close()
            $entryStream.Close()
        }
    }
    $zip.Dispose()
} else {
    Write-Host "No se encontró el archivo zip en $zipFolder"
}

# Copiar archivos .exe de la carpeta ExtensionsPackageInstallers más reciente
$exeDest = Join-Path $tempFolder "ExtensionsPackageInstallers"
New-Item -Path $exeDest -ItemType Directory | Out-Null
if ($installersPath -and (Test-Path $installersPath)) {
    Get-ChildItem -Path $installersPath -Filter *.exe -Recurse | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $exeDest
    }
} else {
    Write-Host "No se encontró la carpeta ExtensionsPackageInstallers en $installersRoot"
}

# Copiar archivos .nupkg de la carpeta pkgs más reciente de K:\Repos\IPRetailV2\CmmSDK\pkgs
$pkgsRootFixed = "K:\Repos\IPRetailV2\CmmSDK\pkgs"
$latestPkgsFolderFixed = Get-ChildItem -Path $pkgsRootFixed -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latestPkgsFolderFixed) {
    $pkgsDest = Join-Path $tempFolder "pkgsIP"
    New-Item -Path $pkgsDest -ItemType Directory | Out-Null
    Get-ChildItem -Path $latestPkgsFolderFixed.FullName -Filter *.nupkg | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $pkgsDest
    }
} else {
    Write-Host "No se encontró la carpeta pkgs más reciente en $pkgsRootFixed"
}

# Crear nombre de zip con fecha y hora actual
$now = Get-Date
$fecha = $now.ToString("yyyyMMdd")
$hora = $now.ToString("HH.mmtt")
$zipName = "AIOPCSU_{0}_{1}.zip" -f $fecha, $hora

# Nueva ruta de destino
$paquetesPath = "K:\Axxon\PaquetesCSU"
if (-not (Test-Path $paquetesPath)) {
    New-Item -Path $paquetesPath -ItemType Directory -Force | Out-Null
}
$finalZipPath = Join-Path $paquetesPath $zipName

# Comprimir carpeta temporal en la nueva ruta
Compress-Archive -Path "$tempFolder\*" -DestinationPath $finalZipPath

Write-Host "Archivo zip creado en: $finalZipPath"

# Limpiar carpeta temporal
Remove-Item -Path $tempFolder -Recurse -Force