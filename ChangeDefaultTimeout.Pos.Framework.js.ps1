#Requires -RunAsAdministrator

# Ruta del archivo que deseas modificar
$rutaDelArchivo = "C:\Program Files\Microsoft Dynamics 365\10.0\Commerce Scale Unit\Microsoft\POS\Pos.Framework.js"

# Lee el contenido del archivo
$contenido = Get-Content -Path $rutaDelArchivo

# Realiza la búsqueda y reemplazo en el contenido
$contenidoModificado = $contenido -replace "PosConfiguration.DEFAULT_CONNECTION_TIMEOUT_IN_SECONDS = 120;", "PosConfiguration.DEFAULT_CONNECTION_TIMEOUT_IN_SECONDS = 120*10; //TIMETOUT_JTORINO"

# Escribe el contenido modificado de vuelta al archivo
$contenidoModificado | Set-Content -Path $rutaDelArchivo
