#Requires -RunAsAdministrator

# Ruta del archivo que deseas modificar
$rutaDelArchivo = "C:\Program Files\Microsoft Dynamics 365\10.0\Commerce Scale Unit\Microsoft\RetailServer\bin\Microsoft.Dynamics.Retail.RetailServer.AspNetCore.dll.config"

[xml]$xml = Get-Content $rutaDelArchivo
# Obtener el nodo padre existente
$nodoPadre = $xml.SelectSingleNode("/configuration/appSettings")

# Verificar si un nodo con el mismo nombre y atributos ya existe
$guardarXml = $false
foreach ($nodoExistente in $nodoPadre.ChildNodes) {

    #HealthCheck.Extensions.ShowAssemblyFiles
    if ($nodoExistente.Name -eq "add" -and $nodoExistente.GetAttribute("key") -eq "HealthCheck.Extensions.ShowAssemblyFiles") {
        $nuevoNodo = $xml.CreateElement("add")
        $nuevoNodo.SetAttribute("key", "HealthCheck.Extensions.ShowAssemblyFiles")
        $nuevoNodo.SetAttribute("value", "true")
        $nodoPadre.PrependChild($nuevoNodo)

        $guardarXml = $true
        break
    }

    #EnableSwagger
    if ($nodoExistente.Name -eq "add" -and $nodoExistente.GetAttribute("key") -eq "HealthCheck.Extensions.ShowAssemblyFiles") {
        $nuevoNodo = $xml.CreateElement("add")
        $nuevoNodo.SetAttribute("key", "EnableSwagger")
        $nuevoNodo.SetAttribute("value", "true")
        $nodoPadre.PrependChild($nuevoNodo)
        $guardarXml = $true
        break
    }
}

if ($guardarXml) {
    $xml.Save($rutaDelArchivo)
}
