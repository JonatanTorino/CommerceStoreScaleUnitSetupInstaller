param (
    [string]$jsonFile
)

# Comprobar si el parámetro no fue pasado
if ($null -eq $jsonFile -or -not (Test-Path -Path $jsonFile)) {
        $nombreEntorno = [System.Environment]::MachineName
        $jsonFileDefault = Get-ChildItem -Path '.\ConfigFiles\' -Filter "$nombreEntorno.json" | Select-Object -ExpandProperty FullName
        Write-Host -ForegroundColor Yellow "Script invacado sin especificar ruta de archivo de configuracion JSON."
        Write-Host -ForegroundColor Yellow "Por lo tanto se busca por defecto el siguiente archivo:"
        Write-Host  "   .\ConfigFiles\$nombreEntorno.json"

        # if ((Test-Path $jsonFile -PathType Leaf) -eq $false) {
        if (($null -ne $jsonFileDefault) -and
        (Test-Path $jsonFileDefault -PathType Any)) {
            Write-Host "ARCHIVO ENCONTRADO"
        }
        else {
            Write-Host -ForegroundColor Red "Archivo no encontrado"
            throw [System.IO.FileNotFoundException] "$jsonFileDefault not found."
        }
    
        $jsonFile = $jsonFileDefault
    }

    Write-Output $jsonFile