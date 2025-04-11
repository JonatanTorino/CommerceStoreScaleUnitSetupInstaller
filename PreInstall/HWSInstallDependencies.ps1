. .\Support\SupportFunctions.ps1
PrintFileName $MyInvocation.MyCommand.Name

$isServerOS = Get-OSInfo

if (!$isServerOS) {
    .\PreInstall\Enable-WCF-HTTP-Activation.ps1
}

Write-Host "Verificación e instalación de dependencias completada."