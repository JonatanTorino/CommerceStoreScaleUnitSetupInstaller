SET ANSI_NULLS, QUOTED_IDENTIFIER ON;
/*ej de uso desde SQLCMD
	SQLCMD -S %SQLServer% -E -i "%Folder%\Restore.sql" -v FileName="%Folder%\%FileName%"
    
    declare @parmInRestoreFileName nvarchar(255) = N'$(FileName)'
*/

--Declaración de variables de entrada desde CLI
declare @parmInAppInsightsInstrumentationKey nvarchar(255) = N'$(AppInsightsInstrumentationKey)'
declare @parmInTelemetryAppName nvarchar(255) = N'$(TelemetryAppName)'
declare @parmInEnvironmentId nvarchar(255) = N'$(EnvironmentId)'

print 'parmInAppInsightsInstrumentationKey = '+@parmInAppInsightsInstrumentationKey
print 'parmInTelemetryAppName = ' +@parmInTelemetryAppName
print 'parmInEnvironmentId = ' +@parmInEnvironmentId
---------------------------------------------------------------------
DELETE FROM AxDB.dbo.SysIntParameters
print 'AxDB.dbo.SysIntParameters, Registro borrado'
INSERT INTO AxDB.dbo.SysIntParameters
	(TELEMETRYAPPNAME, CAPTUREFORMRUN, CAPTUREUSERSESSIONS, CAPTUREXPPEXCEPTIONS, CAPTURECUSTOMMETRICS, CAPTUREWAREHOUSEEVENTS, CAPTURECUSTOMTRACES, CAPTURELONGQUERIES)
	VALUES (@parmInTelemetryAppName, 1, 1, 1, 1, 1, 1, 1)
print 'AxDB.dbo.SysIntParameters, Configuracion agregada para medir telemetria contra la aplicación ' +@parmInTelemetryAppName
---------------------------------------------------------------------
DELETE FROM AxDB.dbo.SysEnvironmentModeMap
print 'AxDB.dbo.SysEnvironmentModeMap, Registro borrado'
INSERT INTO AxDB.dbo.SysEnvironmentModeMap
    (ENVIRONMENTMODE, SYSENVIRONMENTID)
    VALUES (0, @parmInEnvironmentId)
print 'AxDB.dbo.SysEnvironmentModeMap, Configuracion agregada para medir telemetria en modo DEV para el EnviromentId ' +@parmInEnvironmentId 
---------------------------------------------------------------------
DELETE FROM AxDB.dbo.SysIntegrationRegistry
print 'AxDB.dbo.SysIntegrationRegistry, Registro borrado'
INSERT INTO AxDB.dbo.SysIntegrationRegistry
    (ENVIRONMENTMODE, SYSAPPLICATIONNAME, SYSAPPURI)
    VALUES (0, @parmInTelemetryAppName, @parmInAppInsightsInstrumentationKey)
print 'AxDB.dbo.SysIntegrationRegistry, Configuracion agregada para medir telemetria en modo DEV contra el AppInsightsInstrumentationKey ' +@parmInAppInsightsInstrumentationKey 
---------------------------------------------------------------------
DELETE FROM AxDB.dbo.OperationalInsightsParameters
print 'AxDB.dbo.OperationalInsightsParameters, Registro borrado'
INSERT INTO AxDB.dbo.OperationalInsightsParameters
    (CAPTURECOMMERCEEVENTS)
    VALUES (1)
print 'AxDB.dbo.OperationalInsightsParameters, Configuracion agregada para medir telemetria'
---------------------------------------------------------------------
DELETE FROM AxDB.dbo.OperationalInsightsEnvMap
print 'AxDB.dbo.OperationalInsightsEnvMap, Registro borrado'
INSERT INTO AxDB.dbo.OperationalInsightsEnvMap
    (ENVIRONMENTSELECTION, ENVIRONMENTID)
    VALUES (0, @parmInEnvironmentId)
print 'AxDB.dbo.OperationalInsightsEnvMap, Configuracion agregada para medir telemetria en modo DEV para el EnviromentId ' +@parmInEnvironmentId 
---------------------------------------------------------------------
DELETE FROM AxDB.dbo.OperationalInsightsRegistry
print 'AxDB.dbo.OperationalInsightsRegistry, Registro borrado'
INSERT INTO AxDB.dbo.OperationalInsightsRegistry
    (ENVIRONMENTSELECTION, INSTRUMENTATIONKEY)
    VALUES (0, @parmInAppInsightsInstrumentationKey)
print 'AxDB.dbo.OperationalInsightsRegistry, Configuracion agregada para medir telemetria en modo DEV contra el AppInsightsInstrumentationKey ' +@parmInAppInsightsInstrumentationKey 
---------------------------------------------------------------------
UPDATE AxDB.dbo.RETAILSHAREDPARAMETERS
SET [HARDWARESTATIONAPPINSIGHTSINSTRUMENTATIONKEY] = @parmInAppInsightsInstrumentationKey,
	[CLIENTAPPINSIGHTSINSTRUMENTATIONKEY] = @parmInAppInsightsInstrumentationKey,
	[CLOUDPOSAPPINSIGHTSINSTRUMENTATIONKEY] = @parmInAppInsightsInstrumentationKey,
	[RETAILSERVERAPPINSIGHTSINSTRUMENTATIONKEY] = @parmInAppInsightsInstrumentationKey,
	[ASYNCCLIENTAPPINSIGHTSINSTRUMENTATIONKEY] = @parmInAppInsightsInstrumentationKey,
	[WINDOWSPHONEAPPINSIGHTSINSTRUMENTATIONKEY] = @parmInAppInsightsInstrumentationKey,
	[ASYNCSERVERCONNECTORSERVICEAPPINSIGHTSINSTRUMENTATIONKEY] = @parmInAppInsightsInstrumentationKey,
	[REALTIMESERVICEAX63APPINSIGHTSINSTRUMENTATIONKEY] = @parmInAppInsightsInstrumentationKey
print 'AxDB.dbo.RETAILSHAREDPARAMETERS AppInsightsInstrumentationKey actualizados'