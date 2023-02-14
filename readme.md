Esta carpeta cuenta con varios scripts para la instalación inicial de un CommerceScaleUnit (SEALED) estándar de Microsoft.

1) Para la instalación, es necesario tomar el archivo __SAMPLE_Env__.json, y hacer una copia con nombre igual que el entorno.
2) completar los campos del archivo de configuración
3) ejecutar el script InstallScaleUnit.ps1 pasando el fullpath del archivo de configuración creado.

El resto de los archivos Scripts no es necesario modificarlos, al menos que encuentren un error o consideren agregar una mejora.

**InstallScaleUnit.ps1**
Este script invoca a los demás scripts en el orden necesario para la instalación, invocando a scripts que realizan chequeos de dependencias para la instalación, así como a otros posteriores que ajustan valores que vienen por defecto en la instalación.

**CheckD365foConfigDependency.ps1**
Advierte que se requiere agregar de forma manual en la aplicación de D365FO, la configuración de los AppId que se van a usar para esta instalación.

**ChangeAsyncInterval.ps1**
Sirve para cambiar los tiempos de sincronización del AsyncClient.

**CahngeIISWebSitesPath.ps1**
Cambia los IIS WebSite de RetailServer y RetailCloudPos apuntando el PhysicalPath a las rutas de la nueva instalación del CommerceScaleUnit.

**RestoreIISWebSitesPath.ps1**
Restaura los PhysicalPath a su versión original necesario para cuando se ejecutan ServiceUpdates del plaftform de Microsoft
