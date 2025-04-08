Esta carpeta cuenta con varios scripts para la instalación inicial de un CommerceScaleUnit (SEALED) estándar de Microsoft.

* El script InstallScaleUnit.ps1 orquesta la ejecución de los demás ps1.
* El InstallScaleUnit.ps1 recibe como parámetro el path de un archivo json, el cual posee varias propiedades con los parámetros a usar en la instalación y demás scripts.
* La carpeta ConfigFiles posee un archivo el archivo SAMPLE_Config_By_Env_(DuplicateAndRename).json, hacer una copia y aconsejo renombrarlo con el nombre del entorno.
* Aconsejo usar la carpeta ConfigFiles para depositar todos los archivos auxiliares necesarios (el .json, el .exe, el .xml extraido de D365FO).
* Durante la ejecución de los scritps, habrán mensajes que asistan con los requisitos necesarios de configuración en D365FO.

El resto de los archivos Scripts no es necesario modificarlos, al menos que encuentren un error o consideren agregar una mejora.

Descripción de cada script en orden de ejecución:

**InstallScaleUnit.ps1**
Este script invoca a los demás scripts en el orden necesario para la instalación, invocando a scripts que realizan chequeos de dependencias para la instalación, así como a otros posteriores que ajustan valores que vienen por defecto en la instalación.

**CSUCheckJsonFile.ps1**
Se controla que el archivo json con los parámetros de instalación tenga todos los datos necesarios para continuar.

**InsertCmmSDKAzureActiveClientId.ps1**
Toma el archivo de configuracion json para usar los parámetros para insertar en las tablas de la DB de D365FO.

**setCommerceSDK_AzureActiveDirectoryKeys.sql**
Script de SQL para ejecutar insert de los datos tomados del archivo de configuración json.

~~**CheckD365foConfigDependency.ps1****~~ [Discontinuado]
Asiste con la configuración requerida en D365FO, la cual se debe agregar de forma manual en la aplicación.

**CheckRegeditEntriesDependency.ps1**
Ajustas las claves del regedit para el uso de TLS.

~~**CheckNetCoreBundleDependency.ps1**~~ [Discontinuado]
Busca si están instaladas dependencias requeridas, si no las encuentra las descarga e instala. NO está implementado el modo silencioso de instalación.

**CheckAdnDownload.ps1**
Se le pasan dos parámetros, el nombre de un componente para buscar si está instalado y la URL para descargarlo en caso de que no se encuentre. Tiene implementado la instalación en modo silencioso en caso de descargar un MSI.

**ChangePosConfig.ps1**
La instalación del CSU crea un WebSite RSSU sin URLs públicas.
Este script toma la URL del json para setear como endpoint del CommerceRuntime. Junto al ChangeIISWebSitesPath.ps1, sirven para activar los dispositivos.

**ChangeAsyncInterval.ps1**
Cambia los tiempos de sincronización del AsyncClient que vienen por defecto.

**ChangeIISWebSitesPath.ps1**
En las VMs de MSFT vienen WebSite en el IIS para RetailServer y RetailCloudPos. El script cambia el PhysicalPath que trean las VMs por defecto por las rutas de la nueva instalación del CSU.

**RestoreIISWebSitesPath.ps1**
Se usa para restaurar los PhysicalPath a su versión original. Necesario para cuando se ejecutan updates del platform de Microsoft.
