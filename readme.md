Esta carpeta cuenta con varios scripts para la instalación inicial de un CommerceScaleUnit estándar de Microsoft.

**InstallScaleUnit.ps1**
Es el archivo inicial donde se deben proveer los Azure AppId y Thumbprint de certificados para la instalación.
Este script invoca a los demás scripts en el orden necesario para la instalación.

**ChangeAsyncInterval.ps1**
Sirve para cambiar los tiempos de sincronización del AsyncClient.

**CahngeIISWebSitesPath.ps1**
Cambia los IIS WebSite de RetailServer y RetailCloudPos apuntando el PhysicalPath a las rutas de la nueva instalación del CommerceScaleUnit.

**RestoreIISWebSitesPath.ps1**
Restaura los PhysicalPath a su versión original necesario para cuando se ejecutan ServiceUpdates del plaftform de Microsoft
