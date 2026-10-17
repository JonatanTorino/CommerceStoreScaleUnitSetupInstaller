SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @parmInAadPOSId nvarchar(4000) = N'$(AadPOSId)';
DECLARE @parmInAadRetailServerId nvarchar(4000) = N'$(AadRetailServerId)';
DECLARE @parmInAadAsyncClientId nvarchar(4000) = N'$(AadAsyncClientId)';
DECLARE @parmInTenantId nvarchar(4000) = N'$(TenantId)';

SET @parmInAadPOSId = LTRIM(RTRIM(@parmInAadPOSId));
SET @parmInAadRetailServerId = LTRIM(RTRIM(@parmInAadRetailServerId));
SET @parmInAadAsyncClientId = LTRIM(RTRIM(@parmInAadAsyncClientId));
SET @parmInTenantId = LTRIM(RTRIM(@parmInTenantId));

IF NULLIF(@parmInAadPOSId, N'') IS NULL
    THROW 50001, 'AadPOSId es obligatorio.', 1;
IF LEN(@parmInAadPOSId) > 38
    THROW 50016, 'AadPOSId supera la longitud maxima de 38 caracteres.', 1;
IF NULLIF(@parmInAadRetailServerId, N'') IS NULL
    THROW 50002, 'AadRetailServerId es obligatorio.', 1;
IF LEN(@parmInAadRetailServerId) > 38
    THROW 50017, 'AadRetailServerId supera la longitud maxima de 38 caracteres.', 1;
IF NULLIF(@parmInAadAsyncClientId, N'') IS NULL
    THROW 50003, 'AadAsyncClientId es obligatorio.', 1;
IF LEN(@parmInAadAsyncClientId) > 38
    THROW 50018, 'AadAsyncClientId supera la longitud maxima de 38 caracteres.', 1;
IF NULLIF(@parmInTenantId, N'') IS NULL
    THROW 50004, 'TenantId es obligatorio.', 1;
IF LEN(@parmInTenantId) > 255
    THROW 50019, 'TenantId supera la longitud maxima de 255 caracteres.', 1;

PRINT 'parmInAadPOSId = ' + @parmInAadPOSId;
PRINT 'parmInAadRetailServerId = ' + @parmInAadRetailServerId;
PRINT 'parmInAadAsyncClientId = ' + @parmInAadAsyncClientId;
PRINT 'parmInTenantId = ' + @parmInTenantId;

DECLARE @cmmNameCSU nvarchar(100) = 'CmmSDK-CSU';
DECLARE @cmmNameAsync nvarchar(100) = 'CmmSDK-AsyncClient';
DECLARE @cmmNamePos nvarchar(100) = 'CmmSDK-POS';
DECLARE @cmmNameRetailServer nvarchar(100) = 'CmmSDK-RetailServer';

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @TenantId nvarchar(255) = @parmInTenantId;
    SELECT TOP (1) @TenantId = TENANTID
    FROM AxDB.dbo.RETAILSHAREDPARAMETERS;

    IF ((ISNULL(@TenantId, N'') = N'') OR @TenantId <> @parmInTenantId)
        AND (SELECT COUNT(1) FROM AxDB.dbo.RETAILSHAREDPARAMETERS) = 1
    BEGIN
        UPDATE AxDB.dbo.RETAILSHAREDPARAMETERS
        SET TenantId = @parmInTenantId;
        PRINT 'AxDB.dbo.RETAILSHAREDPARAMETERS, TenantId actualizado: ' + @parmInTenantId;
    END

    SET @TenantId = @parmInTenantId;
    DECLARE @UserId nvarchar(20) = 'RetailServiceAccount';

    IF (@parmInAadPOSId = @parmInAadRetailServerId AND @parmInAadPOSId = @parmInAadAsyncClientId)
    BEGIN
        MERGE AxDB.dbo.SysAADClientTable AS destino
        USING (
            SELECT ClientId, [Name], UserId
            FROM (VALUES (@parmInAadPOSId, @cmmNameCSU, @UserId)) AS subquery (ClientId, [Name], UserId)
        ) AS origen
        ON destino.AADCLIENTID = origen.ClientId
        WHEN MATCHED THEN
            UPDATE SET destino.USERID = origen.UserId, destino.[NAME] = origen.[Name]
        WHEN NOT MATCHED THEN
            INSERT (AADCLIENTID, [NAME], USERID)
            VALUES (origen.ClientId, origen.[Name], origen.UserId);
    END
    ELSE
    BEGIN
        MERGE AxDB.dbo.SysAADClientTable AS destino
        USING (
            SELECT ClientId, [Name], UserId
            FROM (
                VALUES
                    (@parmInAadAsyncClientId, @cmmNameAsync, @UserId),
                    (@parmInAadPOSId, @cmmNamePos, @UserId),
                    (@parmInAadRetailServerId, @cmmNameRetailServer, @UserId)
            ) AS subquery (ClientId, [Name], UserId)
        ) AS origen
        ON destino.AADCLIENTID = origen.ClientId
        WHEN MATCHED THEN
            UPDATE SET destino.USERID = origen.UserId, destino.[NAME] = origen.[Name]
        WHEN NOT MATCHED THEN
            INSERT (AADCLIENTID, [NAME], USERID)
            VALUES (origen.ClientId, origen.[Name], origen.UserId);
    END

    PRINT 'AxDB.dbo.SysAADClientTable, Azure Application Id agregados';

    DECLARE @Issuer nvarchar(255) = CONCAT('https://sts.windows.net/', @TenantId, '/');
    DECLARE @ProviderName nvarchar(50) = 'CommerceSDK';
    DECLARE @RETAILIDENTITYPROVIDER_RecId bigint;

    SELECT @RETAILIDENTITYPROVIDER_RecId = RECID
    FROM AxDB.dbo.RETAILIDENTITYPROVIDER
    WHERE Issuer = @Issuer;

    IF @RETAILIDENTITYPROVIDER_RecId IS NULL
    BEGIN
        PRINT 'No se encontro registro en RETAILIDENTITYPROVIDER con Issuer ' + @Issuer;
        INSERT AxDB.dbo.RETAILIDENTITYPROVIDER ([Name], Issuer, [Type])
        VALUES (@ProviderName, @Issuer, 3);
        PRINT 'Insertado';
    END

    SELECT @RETAILIDENTITYPROVIDER_RecId = RECID
    FROM AxDB.dbo.RETAILIDENTITYPROVIDER
    WHERE Issuer = @Issuer;

    IF @RETAILIDENTITYPROVIDER_RecId IS NULL
        THROW 50005, 'No se pudo obtener RetailIdentityProvider.', 1;

    IF NOT EXISTS (
        SELECT 1
        FROM AxDB.dbo.RETAILRELYINGPARTY
        WHERE ClientId = @parmInAadPOSId
    )
    BEGIN
        PRINT 'No se encontro registro en RETAILRELYINGPARTY con ClientId ' + @parmInAadPOSId;
        INSERT AxDB.dbo.RETAILRELYINGPARTY (ProviderId, [Name], ClientId, [Type], UserType)
        VALUES (@RETAILIDENTITYPROVIDER_RecId, 'CmmSDK-POS', @parmInAadPOSId, 1, 2);
        PRINT 'Insertado';
    END

    DECLARE @RETAILRELYINGPARTY_RecId bigint;
    SELECT @RETAILRELYINGPARTY_RecId = RecID
    FROM AxDB.dbo.RETAILRELYINGPARTY
    WHERE ProviderId = @RETAILIDENTITYPROVIDER_RecId
        AND ClientId = @parmInAadPOSId;

    IF @RETAILRELYINGPARTY_RecId IS NULL
        THROW 50006, 'No se pudo obtener RetailRelyingParty.', 1;

    DECLARE @ServerResourceId nvarchar(500) = CONCAT('api://', @parmInAadRetailServerId);

    IF NOT EXISTS (
        SELECT 1
        FROM AxDB.dbo.RETAILSERVERRESOURCE
        WHERE SERVERRESOURCEID = @ServerResourceId
    )
    BEGIN
        PRINT 'No se encontro registro en RETAILSERVERRESOURCE con ServerResourceId ' + @ServerResourceId;
        INSERT AxDB.dbo.RETAILSERVERRESOURCE (RELYINGPARTYID, [Name], ServerResourceId)
        VALUES (@RETAILRELYINGPARTY_RecId, 'CmmSDK-RetailServer', @ServerResourceId);
        PRINT 'Insertado';
    END

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
