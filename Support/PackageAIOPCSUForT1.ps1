param (
    [string]$RepoName
)

if (-not $RepoName) {
    $RepoName = Read-Host "Ingrese el nombre del repositorio"
}

# Construir rutas base
$basePath = "K:\Repos\$RepoName\CmmSDK"
$zipPath = Join-Path $basePath "src\MergedPackage\ScaleUnit\bin\Debug\netstandard2.0\DevAxMergedPackageCSU$RepoName.9.52.0.0.zip"
$installersPath = Join-Path $basePath "ExtensionsPackageInstallers"
$pkgsPath = Join-Path $basePath "pkgsIP"

# Crear carpeta temporal
$tempFolder = Join-Path $env:TEMP ("AIOPCSU_" + [guid]::NewGuid().ToString())
New-Item -Path $tempFolder -ItemType Directory | Out-Null

# Extraer solo la carpeta ext del zip
$extTemp = Join-Path $tempFolder "ext"
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path $zipPath) {
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
    Write-Host "No se encontró el archivo zip en $zipPath"
}

# Copiar archivos .exe de ExtensionsPackageInstallers (recursivo)
$exeDest = Join-Path $tempFolder "ExtensionsPackageInstallers"
New-Item -Path $exeDest -ItemType Directory | Out-Null
if (Test-Path $installersPath) {
    Get-ChildItem -Path $installersPath -Filter *.exe -Recurse | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $exeDest
    }
} else {
    Write-Host "No se encontró la carpeta ExtensionsPackageInstallers en $installersPath"
}

# Copiar carpeta pkgsIP
if (Test-Path $pkgsPath) {
    Copy-Item -Path $pkgsPath -Destination (Join-Path $tempFolder "pkgsIP") -Recurse
} else {
    Write-Host "No se encontró la carpeta pkgsIP en $pkgsPath"
}

# Crear nombre de zip con fecha y hora actual
$now = Get-Date
$fecha = $now.ToString("yyyyMMdd")
$hora = $now.ToString("HH.mmtt")
$zipName = "AIOPCSU_{0}_{1}.zip" -f $fecha, $hora
$desktopPath = [Environment]::GetFolderPath("Desktop")
$finalZipPath = Join-Path $desktopPath $zipName

# Comprimir carpeta temporal en Desktop
Compress-Archive -Path "$tempFolder\*" -DestinationPath $finalZipPath

Write-Host "Archivo zip creado en: $finalZipPath"

# Limpiar carpeta temporal
Remove-Item -Path $tempFolder -Recurse -Force