[CmdletBinding()]
param (
    [string]
    [ValidateNotNullOrEmpty()]$jsonFile
)

. .\Support\SupportFunctions.ps1
PrintFileName $MyInvocation.MyCommand.Name

#Parseo el archivo json para leer sus propiedades
$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

#Inicializo cada variable del json
[string]$AppInsightsInstrumentationKey=$json.AppInsightsInstrumentationKey
[string]$ChannelConfig = $json.ChannelConfig
[string]$EnvironmentId = $json.EnvironmentId

# Cargar el archivo XML
[xml]$xml = Get-Content $ChannelConfig

# Seleccionar todos los nodos 'add' con atributo 'key' que termine en 'AppInsightsInstrumentationKey'
$nodos = $xml.SelectNodes('//add[contains(@key, "AppInsightsInstrumentationKey")]')

# Recorrer y editar los nodos encontrados
foreach ($nodo in $nodos) {
    # Modificar el atributo 'value'
    $nodo.SetAttribute("value", $AppInsightsInstrumentationKey)  # Reemplaza "NuevoValor" con el valor deseado
}

$nodo = $xml.SelectSingleNode('//add[contains(@key, "EnvironmentId")]')
$nodo.SetAttribute("value", $EnvironmentId)  # Reemplaza "NuevoValor" con el valor deseado

# Guardar los cambios en el archivo
$xml.Save($ChannelConfig)

Write-Host "Los atributos 'value' se han editado en el archivo XML."
