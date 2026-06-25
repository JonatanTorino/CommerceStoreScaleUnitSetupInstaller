param (
    [Parameter(Mandatory = $true)]
    [string]
    [ValidateNotNullOrEmpty()]$InstallersFoldersPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet('install', 'uninstall')]
    [ValidateNotNullOrEmpty()]$InstallOrUninstall
)
function Stop-WebAppPoolForce {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    
    try {
        Stop-WebAppPool -Name $Name -ErrorAction SilentlyContinue
        Write-Host "Operacion de detención completada para '$Name'"
    } catch {
        Write-Host "El AppPool '$Name' ya está detenido."
    }
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

if(Test-Path $InstallersFoldersPath){
    Stop-WebAppPoolForce -Name RssuCore
    Stop-WebAppPoolForce -Name RetailServer

    # Listas para almacenar los resultados
    $filesCompletedSuccessfully = @()
    $filesCompletedWithError = @()

    Get-ChildItem -Path $InstallersFoldersPath -Filter *.exe | ForEach-Object {
        $fileName = $_.Name
        Write-Host
        Write-Host
        Write-Host -ForegroundColor Green $fileName "|" $InstallOrUninstall

        # Construye el comando usando las variables
        $command = $_.Fullname + " $InstallOrUninstall"
        # Ejecuta el comando y captura la salida y el código de salida
        Invoke-Expression $command

        # Verificar el código de salida
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$fileName terminó correctamente."
            $filesCompletedSuccessfully += $fileName
        } else {
            Write-Host "$fileName finalizó con un error. Código de salida: $LASTEXITCODE"
            $filesCompletedWithError += $fileName
        }
    }
    # Mostrar el informe final
    Write-Host
    Write-Host
    Write-Host "Informes de finalización:"
    Write-Host -ForegroundColor Green "Archivos que terminaron correctamente:"
    $filesCompletedSuccessfully
    Write-Host
    Write-Host
    Write-Host -ForegroundColor Red "Archivos que terminaron con error:"
    $filesCompletedWithError

    Write-Host 
    Write-Host 
    Start-WebAppPool -Name RssuCore
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