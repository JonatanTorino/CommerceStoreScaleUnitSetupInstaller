# Commerce Store Scale Unit Setup Installer

Este repositorio contiene varios scripts para la instalación inicial de un Commerce Scale Unit (SEALED) estándar de Microsoft. A continuación, se describe el contenido de cada directorio y los scripts que contiene.

## Directorios y Scripts

### ConfigFiles

Este directorio contiene archivos de configuración necesarios para la instalación.

- `SAMPLE_Config_By_Env_(DuplicateAndRename).json`: Archivo de configuración de muestra que debe ser duplicado y renombrado según el entorno.

### Deprecados

Este directorio contiene scripts que han sido discontinuados.

- `ChangeIISWebSitesPath.ps1`: Cambia el PhysicalPath de los sitios web en IIS.
- `RestoreIISWebSitesPath.ps1`: Restaura el PhysicalPath original de los sitios web en IIS.

### PreInstall

Este directorio contiene scripts que se ejecutan antes de la instalación principal.

- `CheckJsonFile.ps1`: Verifica que el archivo JSON de configuración tenga todos los datos necesarios.
- `CheckRegeditEntriesDependency.ps1`: Ajusta las claves del registro para el uso de TLS.
- `InsertApplicationInsightConfigInAxDB.ps1`: Configura Application Insight en AxDB para telemetría.
- `InsertApplicationInsightConfigInAxDB.sql`: Script SQL para insertar la configuración de Application Insight en AxDB.
- `InsertCmmSDKAzureActiveClientId.ps1`: Inserta los AadClientIds y el perfil de comercio en AxDB.
- `InsertCmmSDKAzureActiveClientId.sql`: Script SQL para insertar los Azure Active Directory Client IDs en AxDB.
- `InsertCmmSDKDataInAxDB.ps1`: Inserta datos de configuración en AxDB.
- `InsertCmmSDKProfileConfig.sql`: Script SQL para insertar la configuración del perfil en AxDB.
- `ReplaceXmlAppInsightsInstrumentationKey.ps1`: Reemplaza las claves de AppInsightsInstrumentation en el archivo XML de configuración.

### PostInstall

Este directorio contiene scripts que se ejecutan después de la instalación principal.

- `AddHealthCheckAndEnableSwaggerSetting.ps1`: Agrega configuraciones de HealthCheck y habilita Swagger.
- `ChangeAsyncInterval.ps1`: Cambia los intervalos de sincronización del AsyncClient.
- `ChangeDefaultTimeout.Pos.Framework.js.ps1`: Cambia el tiempo de espera predeterminado en Pos.Framework.js.
- `ChangePosConfig.ps1`: Cambia la configuración del RetailServer por defecto que consulta el POS para activar dispositivos.
- `SetupIISWebSiteCSU.ps1`: Configura el nuevo sitio web de IIS para CSU, con el hostname y bindings del RetailServer para habilitar el acceso público de internet.

### Support

Este directorio contiene scripts de soporte y utilidades.

- `CheckAndDownload.ps1`: Verifica si un componente está instalado y lo descarga si no lo está.
- `CheckGitRepoUpdated.ps1`: Verifica si el repositorio Git está actualizado.
- `GetJsonConfigFile.ps1`: Obtiene el archivo JSON de configuración.

### Scripts Principales

- `CreateLocalConfigFile.ps1`: Crea un archivo de configuración a partir del archivo SAMPLE.json, completando valores que puede recuperados localmente del entorno. No puede completar los AppId o InstrumentationKey.
- `InstallCSU.ps1`: Orquesta la instalación del Commerce Scale Unit.
- `InstallHWS.ps1`: Orquesta la instalación del Hardware Station.
- `Support/RunEveryInstallersInFolder.ps1`: Ejecuta todos los instaladores de extensiones en una carpeta.
- `UpdateAfterRefreshDB.ps1`: Actualiza la configuración después de refrescar la base de datos.
- `UpdateCertificates.ps1`: Actualiza los certificados para CSU. (Útil cuando se hace una rotación de certificados).

## Instrucciones de Uso

1. **Preparar el archivo de configuración JSON**: Ejecute el script `CreateLocalConfigFile.ps1` para crear el archivo automáticamente (este hace backup de existir un archivo previo), o manualmente copie y renombre el archivo `SAMPLE_Config_By_Env_(DuplicateAndRename).json` en el directorio `ConfigFiles` con el nombre del entorno (Hostname). Si ya contaba con un archivo previo, pase las configuraciones faltantes desde el backup al nuevo.
2. **Ejecutar el script de instalación**: Use `InstallCSU.ps1` para instalar el Commerce Scale Unit y `InstallHWS.ps1` para instalar el Hardware Station.
3. **Scripts de soporte**: Utilice los scripts en el directorio `Support` para verificar dependencias y actualizar configuraciones según sea necesario.

Para más detalles sobre cada script, consulte los comentarios dentro de cada archivo.

---

Este archivo README.md proporciona una visión general de los scripts y su propósito dentro del repositorio. Asegúrese de seguir las instrucciones de uso y adaptar los archivos de configuración según su entorno específico.
