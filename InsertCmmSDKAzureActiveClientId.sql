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
declare @parmInRetailServerURL nvarchar(255) = N'$(RetailServerURL)'
declare @parmInCPOSURL nvarchar(255) = N'$(CPOSURL)'

print 'parmInAadPOSId = '+@parmInAadPOSId 
print 'parmInAadRetailServerId = '+@parmInAadRetailServerId
print 'parmInAadAsyncClientId = '+@parmInAadAsyncClientId
print 'parmInTenantId = '+@parmInTenantId
print 'parmInStoreSystemChannelDatabaseId = '+@parmInStoreSystemChannelDatabaseId
print 'parmInRetailServerURL = '+@parmInRetailServerURL
print 'parmInCPOSURL = '+@parmInCPOSURL
-----------------------------------------------------------------------------
declare @cmmNameCSU nvarchar(100) = 'CmmSDK-CSU'
declare @cmmNameAsync nvarchar(100) = 'CmmSDK-AsyncClient'
declare @cmmNamePos nvarchar(100) = 'CmmSDK-POS'
declare @cmmNameRetailServer nvarchar(100) = 'CmmSDK-RetailServer'
---------------------------------------------------------------------
IF (SELECT COUNT(1) FROM AxDB.dbo.RetailChannelProfile
    WHERE [Name] = 'DEFAULT') = 0
BEGIN
    INSERT INTO AxDB.dbo.RetailChannelProfile
        ([ChannelProfileType], [Name])
    VALUES 
        (6, 'Default')
END
declare @RetailChannelProfile_RecId bigint
select @RetailChannelProfile_RecId = RecId from AxDB.dbo.RetailChannelProfile where [Name] = 'Default'
DELETE FROM AxDB.dbo.RetailChannelProfileProperty WHERE ChannelProfile = @RetailChannelProfile_RecId
INSERT INTO AxDB.dbo.RetailChannelProfileProperty
    ([ChannelProfile], [Key_], [Value])
VALUES 
    (@RetailChannelProfile_RecId, 1, @parmInRetailServerURL),
    (@RetailChannelProfile_RecId, 7, @parmInCPOSURL)
---------------------------------------------------------------------
IF (SELECT COUNT(1) FROM AxDB.dbo.RetailConnDatabaseProfile 
    WHERE [Name] = @parmInStoreSystemChannelDatabaseId) = 0
BEGIN
    declare @RetailCDXDataGroup_RecId bigint
    select @RetailCDXDataGroup_RecId = RecId from AxDB.dbo.RetailCDXDataGroup where [Name] = 'Default'
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

IF (@parmInAadPOSId = @parmInAadRetailServerId AND @parmInAadPOSId = @parmInAadAsyncClientId)
BEGIN
    MERGE AxDB.dbo.SysAADClientTable AS destino
    USING (
        SELECT ClientId, [Name], UserId FROM (
            VALUES 
                (@parmInAadPOSId, @cmmNameCSU, @UserId)
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
END
ELSE
BEGIN
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
END
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
