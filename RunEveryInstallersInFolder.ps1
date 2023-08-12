# Requires -RunAsAdministrator

param (
    [Parameter(Mandatory = $true)]
    [string]
    [ValidateNotNullOrEmpty()]$InstallersFoldersPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet('install', 'uninstall')]
    [ValidateNotNullOrEmpty()]$InstallOrUninstall
)

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

if(Test-Path $InstallersFoldersPath){
    C:\Windows\System32\inetsrv\appcmd stop apppool /apppool.name:RssuCore
    C:\Windows\System32\inetsrv\appcmd stop apppool /apppool.name:RetailServer

    # Listas para almacenar los resultados
    $archivosTerminadosCorrectamente = @()
    $archivosTerminadosConError = @()

    Get-ChildItem -Path $InstallersFoldersPath -Filter *.exe | ForEach-Object {
        Write-Host
        Write-Host
        Write-Host -ForegroundColor Green $_.name "|" $InstallOrUninstall
        Start-Process -NoNewWindow -Wait $_.Fullname -ArgumentList $InstallOrUninstall

        $nombreArchivo = $_.Name
        # Verificar el código de salida
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$nombreArchivo terminó correctamente."
            $archivosTerminadosCorrectamente += $nombreArchivo
        } else {
            Write-Host "$nombreArchivo finalizó con un error. Código de salida: $LASTEXITCODE"
            $archivosTerminadosConError += $nombreArchivo
        }
    }
    # Mostrar el informe final
    Write-Host
    Write-Host
    Write-Host "Informes de finalización:"
    Write-Host -ForegroundColor Green "Archivos que terminaron correctamente:"
    $archivosTerminadosCorrectamente
    Write-Host
    Write-Host
    Write-Host -ForegroundColor Red "Archivos que terminaron con error:"
    $archivosTerminadosConError

    Write-Host 
    Write-Host 
    C:\Windows\System32\inetsrv\appcmd stop apppool /apppool.name:RssuCore
    C:\Windows\System32\inetsrv\appcmd start apppool /apppool.name:RetailServer
    Write-Host 
    Write-Host 
}
else{
    Write-Host -ForegroundColor Red  "Path is invalid"
}

$elapsedSecods = $stopwatch.Elapsed
Write-Host -ForegroundColor Green 'Total elapsed time: '
$elapsedSecods
$stopwatch.Stop()