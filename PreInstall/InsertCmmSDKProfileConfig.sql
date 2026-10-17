SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @parmInStoreSystemChannelDatabaseId nvarchar(4000) = N'$(StoreSystemChannelDatabaseId)';
DECLARE @parmInRetailServerURL nvarchar(4000) = N'$(RetailServerURL)';
DECLARE @parmInCPOSURL nvarchar(4000) = N'$(CPOSURL)';

SET @parmInStoreSystemChannelDatabaseId = LTRIM(RTRIM(@parmInStoreSystemChannelDatabaseId));
SET @parmInRetailServerURL = LTRIM(RTRIM(@parmInRetailServerURL));
SET @parmInCPOSURL = LTRIM(RTRIM(@parmInCPOSURL));

IF NULLIF(@parmInStoreSystemChannelDatabaseId, N'') IS NULL
    THROW 50010, 'StoreSystemChannelDatabaseId es obligatorio.', 1;
IF LEN(@parmInStoreSystemChannelDatabaseId) > 255
    THROW 50016, 'StoreSystemChannelDatabaseId supera la longitud maxima de 255 caracteres.', 1;
IF NULLIF(@parmInRetailServerURL, N'') IS NULL
    THROW 50011, 'RetailServerURL es obligatorio.', 1;
IF LEN(@parmInRetailServerURL) > 2046
    THROW 50017, 'RetailServerURL supera la longitud maxima de 2046 caracteres.', 1;
IF NULLIF(@parmInCPOSURL, N'') IS NULL
    THROW 50012, 'CPOSURL es obligatorio.', 1;
IF LEN(@parmInCPOSURL) > 2046
    THROW 50018, 'CPOSURL supera la longitud maxima de 2046 caracteres.', 1;

PRINT 'parmInStoreSystemChannelDatabaseId = ' + @parmInStoreSystemChannelDatabaseId;
PRINT 'parmInRetailServerURL = ' + @parmInRetailServerURL;
PRINT 'parmInCPOSURL = ' + @parmInCPOSURL;

DECLARE @CurrentPartition bigint;
SELECT TOP (1) @CurrentPartition = RecId
FROM AxDB.dbo.PARTITIONS
WHERE PartitionKey = N'initial'
ORDER BY RecId;

IF @CurrentPartition IS NULL
BEGIN
    SELECT TOP (1) @CurrentPartition = RecId
    FROM AxDB.dbo.PARTITIONS
    ORDER BY RecId;
END

IF @CurrentPartition IS NULL
    THROW 50013, 'No se pudo determinar la particion inicial de AxDB.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @RetailChannelProfile_RecId bigint;
    SELECT TOP (1) @RetailChannelProfile_RecId = RecId
    FROM AxDB.dbo.RetailChannelProfile
    WHERE [Name] IN (N'Default', N'DEFAULT')
        AND [Partition] = @CurrentPartition
    ORDER BY CASE WHEN [Name] = N'Default' THEN 0 ELSE 1 END, RecId;

    IF @RetailChannelProfile_RecId IS NULL
    BEGIN
        INSERT AxDB.dbo.RetailChannelProfile ([ChannelProfileType], [Name], [Partition])
        VALUES (6, N'Default', @CurrentPartition);

        SELECT TOP (1) @RetailChannelProfile_RecId = RecId
        FROM AxDB.dbo.RetailChannelProfile
        WHERE [Name] IN (N'Default', N'DEFAULT')
            AND [Partition] = @CurrentPartition
        ORDER BY CASE WHEN [Name] = N'Default' THEN 0 ELSE 1 END, RecId;
    END

    IF @RetailChannelProfile_RecId IS NULL
        THROW 50014, 'No se pudo obtener RetailChannelProfile.', 1;

    IF EXISTS (
        SELECT 1
        FROM AxDB.dbo.RetailChannelProfileProperty
        WHERE ChannelProfile = @RetailChannelProfile_RecId
            AND [Key_] = 1
            AND [Partition] = @CurrentPartition
    )
    BEGIN
        UPDATE AxDB.dbo.RetailChannelProfileProperty
        SET [Value] = @parmInRetailServerURL
        WHERE ChannelProfile = @RetailChannelProfile_RecId
            AND [Key_] = 1
            AND [Partition] = @CurrentPartition;
    END
    ELSE
    BEGIN
        INSERT AxDB.dbo.RetailChannelProfileProperty ([ChannelProfile], [Key_], [Value], [Partition])
        VALUES (@RetailChannelProfile_RecId, 1, @parmInRetailServerURL, @CurrentPartition);
    END

    IF EXISTS (
        SELECT 1
        FROM AxDB.dbo.RetailChannelProfileProperty
        WHERE ChannelProfile = @RetailChannelProfile_RecId
            AND [Key_] = 7
            AND [Partition] = @CurrentPartition
    )
    BEGIN
        UPDATE AxDB.dbo.RetailChannelProfileProperty
        SET [Value] = @parmInCPOSURL
        WHERE ChannelProfile = @RetailChannelProfile_RecId
            AND [Key_] = 7
            AND [Partition] = @CurrentPartition;
    END
    ELSE
    BEGIN
        INSERT AxDB.dbo.RetailChannelProfileProperty ([ChannelProfile], [Key_], [Value], [Partition])
        VALUES (@RetailChannelProfile_RecId, 7, @parmInCPOSURL, @CurrentPartition);
    END

    IF NOT EXISTS (
        SELECT 1
        FROM AxDB.dbo.RetailConnDatabaseProfile
        WHERE [Name] = @parmInStoreSystemChannelDatabaseId
            AND [Partition] = @CurrentPartition
    )
    BEGIN
        DECLARE @RetailCDXDataGroup_RecId bigint;
        SELECT TOP (1) @RetailCDXDataGroup_RecId = RecId
        FROM AxDB.dbo.RetailCDXDataGroup
        WHERE [Name] IN (N'Default', N'DEFAULT')
            AND [Partition] = @CurrentPartition
        ORDER BY CASE WHEN [Name] = N'Default' THEN 0 ELSE 1 END, RecId;

        IF @RetailCDXDataGroup_RecId IS NULL
            THROW 50015, 'No se encontro RetailCDXDataGroup Default.', 1;

        INSERT AxDB.dbo.RetailConnDatabaseProfile ([Name], [DataGroup], [Partition])
        VALUES (@parmInStoreSystemChannelDatabaseId, @RetailCDXDataGroup_RecId, @CurrentPartition);

        PRINT 'AxDB.dbo.RetailConnDatabaseProfile, ChannelDatabase insertada';
        PRINT '[Name]: ' + @parmInStoreSystemChannelDatabaseId;
        PRINT '[DataGroup]: ' + CAST(@RetailCDXDataGroup_RecId AS nvarchar(50));
    END

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
