#Requires -RunAsAdministrator

# Ruta del archivo que deseas modificar
$rutaDelArchivo = "C:\Program Files\Microsoft Dynamics 365\10.0\Commerce Scale Unit\Microsoft\RetailServer\bin\Microsoft.Dynamics.Retail.RetailServer.AspNetCore.dll.config"

[xml]$xml = Get-Content $rutaDelArchivo
# Obtener el nodo padre existente
$nodoPadre = $xml.SelectSingleNode("/configuration/appSettings")

# Verificar si un nodo con el mismo nombre y atributos ya existe
$guardarXml = $false
$nodeNotFoundHealthCheck = $true
$nodeNotFoundEnableSwagger = $true
foreach ($nodoExistente in $nodoPadre.ChildNodes) {

    #HealthCheck.Extensions.ShowAssemblyFiles
    if ($nodoExistente.GetAttribute("key") -eq "HealthCheck.Extensions.ShowAssemblyFiles") {
        $nodeNotFoundHealthCheck = $false
    }

    #EnableSwagger
    if ($nodoExistente.Name -eq "add" -and $nodoExistente.GetAttribute("key") -eq "EnableSwagger") {
        $nodeNotFoundEnableSwagger = $false
    }

    if ($nodeNotFoundHealthCheck -eq $false -and $nodeNotFoundEnableSwagger -eq $false) {
        break
    }
}

if ($nodeNotFoundHealthCheck) {
    Write-Host "No se encontró ningún nodo <add> con el key 'HealthCheck.Extensions.ShowAssemblyFiles'"
    # Aquí puedes realizar cualquier acción que necesites cuando no encuentres el nodo
    $nuevoNodo = $xml.CreateElement("add")
    $nuevoNodo.SetAttribute("key", "HealthCheck.Extensions.ShowAssemblyFiles")
    $nuevoNodo.SetAttribute("value", "true")
    $nodoPadre.PrependChild($nuevoNodo)

    $guardarXml = $true
}

if ($nodeNotFoundEnableSwagger){
    Write-Host "No se encontró ningún nodo <add> con el key 'EnableSwagger'"
    # Aquí puedes realizar cualquier acción que necesites cuando no encuentres el nodo
    $nuevoNodo = $xml.CreateElement("add")
    $nuevoNodo.SetAttribute("key", "EnableSwagger")
    $nuevoNodo.SetAttribute("value", "true")
    $nodoPadre.PrependChild($nuevoNodo)
    $guardarXml = $true
}

if ($guardarXml) {
    $xml.Save($rutaDelArchivo)
}
