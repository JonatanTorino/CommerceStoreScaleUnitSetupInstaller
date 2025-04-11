
. .\Support\SupportFunctions.ps1
PrintFileName $MyInvocation.MyCommand.Name

# El nombre de la característica para la Activación HTTP de WCF bajo .NET Framework 4.5+ suele ser este.
$featureName = "WCF-HTTP-Activation" 

Write-Host "Comprobando el estado de la característica de Windows: $featureName ..."

try {
    # Obtener el estado de la característica. -ErrorAction Stop detendrá el script si la característica no se encuentra.
    $features = Get-WindowsOptionalFeature -Online | Where-Object FeatureName -Like "*WCF-HTTP*" -ErrorAction Stop

    foreach ($feature in $features) {
        if ($feature.State -ne [Microsoft.Dism.Commands.FeatureState]::Enabled) {
            Write-Host "Habilitando la característica '$($feature.FeatureName)'..."
            Enable-WindowsOptionalFeature -Online -FeatureName $feature.FeatureName -All -ErrorAction Stop
            Write-Host "La característica '$($feature.FeatureName)' ha sido habilitada correctamente."
        } 
    }
} catch [Microsoft.Dism.Commands.ImageNotFoundException] {
    # Capturar error específico si la característica no se encuentra
     Write-Error "Característica '$featureName' no encontrada. Esto podría indicar un nombre de característica incorrecto para tu versión de Windows."
     Write-Host "Listando características WCF HTTP potencialmente relevantes:"
     # Mostrar características similares para ayudar a encontrar la correcta
     Get-WindowsOptionalFeature -Online | Where-Object {$_.FeatureName -like "*WCF*HTTP*"} | Select-Object FeatureName, State
} catch {
    # Capturar cualquier otro error durante el proceso
    Write-Error "Ocurrió un error al comprobar o habilitar la característica '$featureName': $($_.Exception.Message)"
}
