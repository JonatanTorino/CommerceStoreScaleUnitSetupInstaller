# Instalación de HWS

## Descargar el repositorio desde GitHub

- [CommerceStoreScaleUnitSetupInstaller](https://github.com/JonatanTorino/CommerceStoreScaleUnitSetupInstaller)
Si descargan el ZIP usando el botón verde. No olvidar hacer boton derecho > propiedades > marcar la opcion "unblock"

## Descargar instalador y configuración

Desde el entorno de BO, navegar y abrir el registro de la tienda con la que van a trabajar, en la sección "Hardware Station":

- Crear una registro para la HWS considerando los siguientes campos
  - HostName: debe ser igual al de la terminal donde se instalará.
  - Port: 450 (o el que prefieran).
  - Package Reference: elegir la versión del instalador que coincida con la versión del servidor de tienda.
- Guardar y en la barra de botones de la sección usar los botones:
  - <a id="Download">Download</a>: descargar el instalador en la ruta donde descargamos el repositorio de CommerceStoreScaleUnitSetupInstaller, dentro de una carpeta HWS.[##version]
  - <a id="ConfigFile">Configuration File</a> : descargar el XML dentro de la carpeta ConfigFile del repositorio de CommerceStoreScaleUnitSetupInstaller.

## Uso del repositorio CommerceStoreScaleUnitSetupInstaller descargado

Abrir el powershell en modo administrador

- posicionarse en la carpeta del repositorio

  ```powershell
  CD [RutaDelRepositorio]
  ```

- Solo la primera vez ejecutar el script:

  ```powershell
  .\CreateLocalConfigFileForHWS.ps1
  ```

- Si reciben un error por las ExecutionPolicy, se pueden habilitar el uso de estos scripts ejecutando el comando, luego pueden volver a ejecutar el CreateLocalConfigFileForHWS.ps1

  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy Unrestricted
  ```

- Se creará un archivo de configuración con el nombre del equipo en la carpeta .\Config\[NombreHost].HWS.json
- Editar el json colocando la ruta completa de los archivos descargados Configuración [Download] (##Download) y [Configuration File] (##ConfigFile)

  !!! note: Usar dobles barras \\\ como separador de carpetas.
  
- Ejecutar el script de instalación, si pide reiniciar indicar que NO.

  ```powershell
  .\InstallHWS.ps1
  ```
  
  !!! note: Si se instalaron componentes faltantes puede fallar la instalación. En ese caso reiniciar el sistema operativo y volver a ejecutar solo el script de instalación.
