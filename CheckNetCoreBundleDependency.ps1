Write-Host 
Write-Host "========================================"
Write-Host "       CheckNetCoreBundleDependency     "
Write-Host "========================================"
Write-Host 

Write-Host "Este proceso de busqueda puede tardar varios minutos, " -ForegroundColor Green
Write-Host "si ya posee instalado Hosting Bundle puede saltear este proceso" -ForegroundColor Green
$continuar = $false
$preguntar = $true
while ($preguntar) 
{
    $respuesta = Read-Host -Prompt "¿Desea continuar con la búsqueda? [Y|N]"
    if ($respuesta -eq "Y" -or $respuesta -eq "N")
    {
        $preguntar = $false
        $continuar = $respuesta -eq "Y"
    }
}

if ($continuar)
{
    #Reemplazar el string por el patron del programa que se desee buscar
    $SearchTerm = "Hosting Bundle"
    Write-Host -ForegroundColor yellow "Buscando si esta instalado " $SearchTerm
    $InstalledOptions = wmic product get description | findstr /C:$SearchTerm

    #Programa y versión concreta a buscar
    $HostingBudle606 = "Microsoft ASP.NET Core 6.0.6 Hosting Bundle Options"

    if (!$InstalledOptions -or (-NOT (@("$InstalledOptions") -match $HostingBudle606))) {
        Write-Host -ForegroundColor Yellow "No encontrado"
        Write-Host -ForegroundColor yellow "Descargando " $HostingBudle606
        Write-Host -ForegroundColor yellow "Descargando ..."
        Write-Host 

        $url = "https://download.visualstudio.microsoft.com/download/pr/0d000d1b-89a4-4593-9708-eb5177777c64/cfb3d74447ac78defb1b66fd9b3f38e0/dotnet-hosting-6.0.6-win.exe"
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12'
        Invoke-WebRequest -Uri $url -OutFile "$env:temp\dotnet-hosting-6.0.6-win.exe"
        Write-Host -ForegroundColor yellow "`nInstalling '$HostingBudle606', please follow the step on the installer window..."
        Start-Process "$env:temp\dotnet-hosting-6.0.6-win.exe" -Wait
    }
    else {
        Write-Host -ForegroundColor Yellow "`n "$HostingBudle606" is already installed !!"
    }
}
