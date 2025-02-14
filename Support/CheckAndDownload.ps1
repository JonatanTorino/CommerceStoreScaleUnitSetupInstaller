#Requires -RunAsAdministrator

param (
    [parameter(Mandatory = $true
        , HelpMessage = "Nombre del compontente a buscar si esta instalado")
    ]
    [string]
    [ValidateNotNullOrEmpty()]$searchTerm,
    
    [parameter(Mandatory = $true
        , HelpMessage = "URL para descargar el componente ")
    ]
    [string]
    [ValidateNotNullOrEmpty()]$downloadURL
) 

$currentFileName = (Get-Item $PSCommandPath).Name
Write-Host 
Write-Host "========================================"
Write-Host "    $currentFileName : $searchTerm "
Write-Host "========================================"
Write-Host 

Write-Host "Este proceso de busqueda puede tardar varios minutos, " -ForegroundColor Green
Write-Host "si ya posee instalado '$searchTerm' puede saltear este proceso" -ForegroundColor Green
$continuar = $false
$preguntar = $true
while ($preguntar) {
    $respuesta = Read-Host -Prompt "¿Desea continuar con la búsqueda? [Y|N]"
    if ($respuesta -eq "Y" -or $respuesta -eq "N") {
        $preguntar = $false
        $continuar = $respuesta -eq "Y"
    }
}

if ($continuar) {
    #Reemplazar el string por el patron del programa que se desee buscar
    Write-Host 
    Write-Host -ForegroundColor yellow "Buscando si esta instalado '$searchTerm'"
    $InstalledOptions = wmic product get description | findstr /C:$searchTerm

    #Programa y versión concreta a buscar
    if (!$InstalledOptions -or (-NOT (@("$InstalledOptions") -match $searchTerm))) {
        Write-Host -ForegroundColor Yellow "No encontrado"
        Write-Host -ForegroundColor yellow "Descargando " $searchTerm
        Write-Host -ForegroundColor yellow "Descargando ..."

        # Dividir la URL por "/" y obtener el último elemento que será el nombre del archivo
        $downloadFileName = $downloadURL.Split("/")[-1]
        $downloadPath = "$env:temp\$downloadFileName"
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12'
        Invoke-WebRequest -Uri $downloadURL -OutFile $downloadPath

        $fileNameExt = Get-ChildItem $downloadPath | Select-Object Extension 
        switch ($fileNameExt.Extension) {
            ".msi" { 
                Write-Host -ForegroundColor yellow "`nInstallando '$searchTerm' en modo silencioso"
                Start-Process -Wait -FilePath "$env:temp\$downloadFileName" -ArgumentList "/quiet /norestart"
            }
            ".exe" { 
                Write-Host -ForegroundColor yellow "`nInstallando '$searchTerm' en modo silencioso"
                Start-Process -Wait -FilePath "$env:temp\$downloadFileName" -ArgumentList "/quiet /norestart"
            }
            Default {
                Write-Host -ForegroundColor yellow "`nSe ejecutará '$searchTerm', por favor siga los pasos de la ventana del instalador..."
                Start-Process "$env:temp\$downloadFileName" -Wait
            }
        }

        Write-Host -ForegroundColor Green "'$searchTerm' instalado"
    }
    else {
        Write-Host -ForegroundColor Blue "`n "$searchTerm" is already installed !!"
        Write-Host 
    }
}
