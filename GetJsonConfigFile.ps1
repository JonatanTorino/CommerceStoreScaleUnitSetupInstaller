param (
    [string]$jsonFile
)

# Comprobar si el parámetro no fue pasado
if ([string]::IsNullOrEmpty($jsonFile) -or -not (Test-Path -Path $jsonFile -PathType Leaf)) {
    $nombreEntorno = [System.Environment]::MachineName
    $ConfigFiles = '.\ConfigFiles\'
    $rutaArchivoEntorno = $ConfigFiles + $nombreEntorno + ".json"
    $jsonFileDefault = Get-ChildItem -Path $ConfigFiles -Filter "$nombreEntorno.json" | Select-Object -ExpandProperty FullName
    Write-Host -ForegroundColor Yellow "Script invacado sin especificar ruta de archivo de configuracion JSON."
    Write-Host -ForegroundColor Yellow "Por lo tanto se busca por defecto el siguiente archivo:"
    Write-Host  "   $rutaArchivoEntorno"

    # if ((Test-Path $jsonFile -PathType Leaf) -eq $false) {
    if (($null -ne $jsonFileDefault) -and
        (Test-Path $jsonFileDefault -PathType Any)) {
        Write-Host -ForegroundColor Green "ARCHIVO ENCONTRADO"
    }
    else {
        Write-Host -ForegroundColor Red "Archivo no encontrado: $rutaArchivoEntorno"
        throw [System.IO.FileNotFoundException] "$rutaArchivoEntorno not found."
    }
    
    $jsonFile = $jsonFileDefault
}

Write-Output $jsonFile