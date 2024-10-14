SET ANSI_NULLS, QUOTED_IDENTIFIER ON;
/*ej de uso desde SQLCMD
	SQLCMD -S %SQLServer% -E -i "%Folder%\Restore.sql" -v FileName="%Folder%\%FileName%"
    
    declare @parmInRestoreFileName nvarchar(255) = N'$(FileName)'
*/

--Declaración de variables de entrada desde CLI
declare @parmInStoreSystemChannelDatabaseId nvarchar(255) = N'$(StoreSystemChannelDatabaseId)'
declare @parmInRetailServerURL nvarchar(255) = N'$(RetailServerURL)'
declare @parmInCPOSURL nvarchar(255) = N'$(CPOSURL)'

print 'parmInStoreSystemChannelDatabaseId = '+@parmInStoreSystemChannelDatabaseId
print 'parmInRetailServerURL = '+@parmInRetailServerURL
print 'parmInCPOSURL = '+@parmInCPOSURL
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
