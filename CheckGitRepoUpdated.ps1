param (
    [string]$rutaRepositorio
)

# Nombre de la rama que deseas verificar (por ejemplo, "main" o "master")
$nombreRama = "main"

# Cambia al directorio del repositorio
Set-Location $rutaRepositorio

# Verifica si hay cambios pendientes en la rama local
if ((git status -s) -eq $null) {
    Write-Host "El repositorio no tiene cambios pendientes en la rama local."
} else {
    Write-Host "El repositorio tiene cambios pendientes en la rama local. Debes confirmarlos o descartarlos antes de verificar la actualización."
}

# Actualiza la información de la rama remota
git fetch origin $nombreRama

# Compara la rama local con la rama remota
if ((git rev-list HEAD...origin/$nombreRama --count) -eq 0) {
    Write-Host "El repositorio está actualizado al día."
    Write-Host -ForegroundColor Green "para actualizar ejecute un git pull"
} else {
    throw [System.IO.FileNotFoundException] "El repositorio no está actualizado. Hay cambios en la rama remota."
}