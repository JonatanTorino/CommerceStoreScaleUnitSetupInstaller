SET ANSI_NULLS, QUOTED_IDENTIFIER ON;
/*ej de uso desde SQLCMD
	SQLCMD -S %SQLServer% -E -i "%Folder%\Restore.sql" -v FileName="%Folder%\%FileName%"
    
    declare @parmInRestoreFileName nvarchar(255) = N'$(FileName)'
*/

--Declaración de variables de entrada desde CLI
declare @parmInAadPOSId nvarchar(38) = N'$(AadPOSId)'
declare @parmInAadRetailServerId nvarchar(38) = N'$(AadRetailServerId)'
declare @parmInAadAsyncClientId nvarchar(38) = N'$(AadAsyncClientId)'
declare @parmInTenantId nvarchar(255) = N'$(TenantId)'
declare @parmInStoreSystemChannelDatabaseId nvarchar(255) = N'$(StoreSystemChannelDatabaseId)'
declare @parmInAppInsightsInstrumentationKey nvarchar(255) = N'$(AppInsightsInstrumentationKey)'
declare @parmInTelemetryAppName nvarchar(255) = N'$(TelemetryAppName)'
declare @parmInEnvironmentId nvarchar(255) = N'$(EnvironmentId)'

print 'parmInAadPOSId = '+@parmInAadPOSId 
print 'parmInAadRetailServerId = '+@parmInAadRetailServerId
print 'parmInAadAsyncClientId = '+@parmInAadAsyncClientId
print 'parmInTenantId = '+@parmInTenantId
print 'parmInStoreSystemChannelDatabaseId = '+@parmInStoreSystemChannelDatabaseId
print 'parmInAppInsightsInstrumentationKey = '+@parmInAppInsightsInstrumentationKey
print 'parmInTelemetryAppName = ' +@parmInTelemetryAppName
print 'parmInEnvironmentId = ' +@parmInEnvironmentId
-----------------------------------------------------------------------------
declare @cmmNameAsync nvarchar(100) = 'CmmSDK-AsyncClient'
declare @cmmNamePos nvarchar(100) = 'CmmSDK-POS'
declare @cmmNameRetailServer nvarchar(100) = 'CmmSDK-RetailServer'
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
---------------------------------------------------------------------
IF (SELECT COUNT(1) FROM AxDB.dbo.RetailConnDatabaseProfile 
    WHERE [Name] = @parmInStoreSystemChannelDatabaseId) = 0
BEGIN
    declare @RetailCDXDataGroup_RecId bigint
    select @RetailCDXDataGroup_RecId = RecID from AxDB.dbo.RetailCDXDataGroup where [Name] = 'Default'
    INSERT INTO AxDB.dbo.RetailConnDatabaseProfile
            ([Name], [DataGroup])
    VALUES (@parmInStoreSystemChannelDatabaseId, @RetailCDXDataGroup_RecId)
    
    print 'AxDB.dbo.RetailConnDatabaseProfile, ChannelDatabase no encontrada, insertada'
    print '[Name]: '+ @parmInStoreSystemChannelDatabaseId
    print '[DataGroup]: '+ @RetailCDXDataGroup_RecId
END
---------------------------------------------------------------------
declare @TenantId nvarchar(255) = N'$(TenantId)'
select top 1 @TenantId = TENANTID from AxDB.dbo.RETAILSHAREDPARAMETERS
IF ((ISNULL(@TenantId, '') = '') OR @TenantId <> @parmInTenantId) 
    AND (SELECT COUNT(1) FROM AxDB.dbo.RETAILSHAREDPARAMETERS) = 1
BEGIN
	update AxDB.dbo.RETAILSHAREDPARAMETERS set TenantId = @parmInTenantId
    print 'AxDB.dbo.RETAILSHAREDPARAMETERS, TenantId no encontrado, actualizado: '+@parmInTenantId
END
set @TenantId = @parmInTenantId
----------------------------------------------------------------
declare @UserId nvarchar(20) = 'RetailServiceAccount'

MERGE AxDB.dbo.SysAADClientTable AS destino
USING (
    SELECT ClientId, [Name], UserId FROM (
        VALUES 
            (@parmInAadAsyncClientId, @cmmNameAsync, @UserId),
            (@parmInAadPOSId, @cmmNamePos, @UserId),
            (@parmInAadRetailServerId, @cmmNameRetailServer, @UserId)
    ) AS subquery (ClientId, [Name], UserId)
) AS origen
ON (destino.AADCLIENTID = origen.ClientId) -- Condición de combinación

-- Si hay una coincidencia, actualiza los valores
WHEN MATCHED THEN
    UPDATE SET destino.USERID = origen.UserId, destino.[NAME] = origen.[Name]

-- Si no hay una coincidencia, inserta los valores
WHEN NOT MATCHED THEN
    INSERT (AADCLIENTID, [NAME], USERID)
    VALUES (origen.ClientId, origen.[Name], origen.UserId);

print 'AxDB.dbo.SysAADClientTable, Azure Application Id agregados'
-----------------------------------------------------------------------------
declare @Issuer nvarchar(255) = Concat('https://sts.windows.net/', @TenantId, '/')
declare @ProviderName nvarchar(50) = 'CommerceSDK'
declare @RETAILIDENTITYPROVIDER_RecId bigint
select @RETAILIDENTITYPROVIDER_RecId = RECID from AxDB.dbo.RETAILIDENTITYPROVIDER WHERE Issuer = @Issuer
IF @RETAILIDENTITYPROVIDER_RecId IS NULL
BEGIN
    print 'No se encontró registro en RETAILIDENTITYPROVIDER con Issuer ' + @Issuer
    Insert AxDB.dbo.RETAILIDENTITYPROVIDER([Name], Issuer, [Type])
    values(@ProviderName, @Issuer, 3)
    print 'Insertado'
END
select @RETAILIDENTITYPROVIDER_RecId = RECID from AxDB.dbo.RETAILIDENTITYPROVIDER WHERE Issuer = @Issuer
-----------------------------------------------------------------------------
IF NOT EXISTS (select 1 from AxDB.dbo.RETAILRELYINGPARTY where ClientId = @parmInAadPOSId)
BEGIN
    print 'No se encontró registro en RETAILRELYINGPARTY con ClientId ' + @parmInAadPOSId
	insert AxDB.dbo.RETAILRELYINGPARTY(ProviderId, [Name], ClientId, [Type], UserType)
	values(@RETAILIDENTITYPROVIDER_RecId, 'CmmSDK-POS', @parmInAadPOSId, 1 /*Public*/, 2 /*Worker*/)
    print 'Insertado'
END
-----------------------------------------------------------------------------
declare @RETAILRELYINGPARTY_RecId bigint
select @RETAILRELYINGPARTY_RecId = RecID from AxDB.dbo.RETAILRELYINGPARTY where ProviderId = @RETAILIDENTITYPROVIDER_RecId and ClientId = @parmInAadPOSId
declare @ServerResourceId nvarchar(500) = Concat('api://', @parmInAadRetailServerId)
IF NOT EXISTS (select 1 from AxDB.dbo.RETAILSERVERRESOURCE where SERVERRESOURCEID = @ServerResourceId)
BEGIN
    print 'No se encontró registro en RETAILSERVERRESOURCE con ServerResourceId ' + @ServerResourceId
	Insert AxDB.dbo.RETAILSERVERRESOURCE(RELYINGPARTYID, [Name], ServerResourceId)
	values(@RETAILRELYINGPARTY_RecId, 'CmmSDK-RetailServer', @ServerResourceId)
    print 'Insertado'
END
