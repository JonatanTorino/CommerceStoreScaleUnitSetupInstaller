#Requires -RunAsAdministrator

# Ruta del archivo que deseas modificar
$rutaDelArchivo = "C:\Program Files\Microsoft Dynamics 365\10.0\Commerce Scale Unit\Microsoft\RetailServer\bin\Microsoft.Dynamics.Retail.RetailServer.AspNetCore.dll.config"

[xml]$xml = Get-Content $rutaDelArchivo
$nodoPadre = $xml.SelectSingleNode("/configuration/appSettings")

#HealthCheck.Extensions.ShowAssemblyFiles
$nuevoNodo = $xml.CreateElement("add")
$nuevoNodo.SetAttribute("key", "HealthCheck.Extensions.ShowAssemblyFiles")
$nuevoNodo.SetAttribute("value", "true")
$nodoPadre.PrependChild($nuevoNodo)

#EnableSwagger
$nuevoNodo = $xml.CreateElement("add")
$nuevoNodo.SetAttribute("key", "EnableSwagger")
$nuevoNodo.SetAttribute("value", "true")
$nodoPadre.PrependChild($nuevoNodo)

$xml.Save($rutaDelArchivo)
