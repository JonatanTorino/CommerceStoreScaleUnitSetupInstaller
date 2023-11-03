param (
    [string]$rutaRepositorio
)

# Nombre de la rama que deseas verificar (por ejemplo, "main" o "master")
$nombreRama = "main"

# Cambia al directorio del repositorio
Set-Location $rutaRepositorio

# Verifica si hay cambios pendientes en la rama local
if ($null -eq (git status -s)) {
    Write-Host "El repositorio no tiene cambios pendientes en la rama local."
} else {
    Write-Host -ForegroundColor Yellow "El repositorio tiene cambios pendientes en la rama local. Debes confirmarlos o descartarlos si fuese necesario descargar actualizaciones del repositorio remota."
    Write-Host "Repositorio remoto"
    Write-Host "    $rutaRepositorio"
}

# Actualiza la información de la rama remota
git fetch origin $nombreRama

# Compara la rama local con la rama remota
if ((git rev-list HEAD...origin/$nombreRama --count) -eq 0) {
    Write-Host "El repositorio está actualizado al día."
} else {
    Write-Host "El repositorio no está actualizado. Hay cambios en la rama remota."
    Write-Host -ForegroundColor Green "para actualizar ejecute un git pull"
    throw [System.IO.FileNotFoundException] "Secuencia cancelada"
}