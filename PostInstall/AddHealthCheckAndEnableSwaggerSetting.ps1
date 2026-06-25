#Requires -RunAsAdministrator

. .\Support\SupportFunctions.ps1
PrintFileName $MyInvocation.MyCommand.Name

# Ruta del archivo que deseas modificar
$filePath = "C:\Program Files\Microsoft Dynamics 365\10.0\Commerce Scale Unit\Microsoft\RetailServer\bin\Microsoft.Dynamics.Retail.RetailServer.AspNetCore.dll.config"

[xml]$xml = Get-Content $filePath
# Obtener el nodo padre existente
$parentNode = $xml.SelectSingleNode("/configuration/appSettings")

# Verificar si un nodo con el mismo nombre y atributos ya existe
$saveXml = $false
$nodeNotFoundHealthCheck = $true
$nodeNotFoundEnableSwagger = $true
foreach ($existingNode in $parentNode.ChildNodes) {
    if ($existingNode.NodeType -eq "Comment") { continue }

    #HealthCheck.Extensions.ShowAssemblyFiles
    if ($existingNode.GetAttribute("key") -eq "HealthCheck.Extensions.ShowAssemblyFiles") {
        $nodeNotFoundHealthCheck = $false
    }

    #EnableSwagger
    if ($existingNode.Name -eq "add" -and $existingNode.GetAttribute("key") -eq "EnableSwagger") {
        $nodeNotFoundEnableSwagger = $false
    }

    if ($nodeNotFoundHealthCheck -eq $false -and $nodeNotFoundEnableSwagger -eq $false) {
        break
    }
}

if ($nodeNotFoundHealthCheck) {
    Write-Host "No se encontró ningún nodo <add> con el key 'HealthCheck.Extensions.ShowAssemblyFiles'"
    # Aquí puedes realizar cualquier acción que necesites cuando no encuentres el nodo
    $newNode = $xml.CreateElement("add")
    $newNode.SetAttribute("key", "HealthCheck.Extensions.ShowAssemblyFiles")
    $newNode.SetAttribute("value", "true")
    $parentNode.PrependChild($newNode)
    Write-Host -ForegroundColor Green "Se agrego un nodo <add> con el key 'HealthCheck.Extensions.ShowAssemblyFiles'"

    $saveXml = $true
}

if ($nodeNotFoundEnableSwagger) {
    Write-Host "No se encontró ningún nodo <add> con el key 'EnableSwagger'"
    # Aquí puedes realizar cualquier acción que necesites cuando no encuentres el nodo
    $newNode = $xml.CreateElement("add")
    $newNode.SetAttribute("key", "EnableSwagger")
    $newNode.SetAttribute("value", "true")
    $parentNode.PrependChild($newNode)
    Write-Host -ForegroundColor Green "Se agrego un nodo <add> con el key 'EnableSwagger'"

    $saveXml = $true
}

if ($saveXml) {
    $xml.Save($filePath)
}
