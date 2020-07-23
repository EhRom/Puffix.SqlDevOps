-- Script to maintain the indexes and statistics in your database.
-- Replace <MyDatabase> by your database name.
USE [<MyDatabase>]
GO

DECLARE @reorganizeTreshold numeric(10,7) = 5.0;
DECLARE @rebuildTreshold numeric(10,7) = 30.0;

PRINT 'Mise à jour des statistiques de la base ' + CAST(DB_NAME() AS varchar);

EXEC sys.sp_updatestats;

DECLARE @indexInformation TABLE 
(
	SchemaName		sysname not null,
	TableName		sysname not null,
	IndexName		sysname not null,
	IsColumnstore	bit not null,
	AllowPageLocks	bit not null,
	PartitionCount	int not null,
	PartitionNumber	int not null,
	Fragementation	numeric(10,7) not null,
	UNIQUE CLUSTERED (SchemaName, TableName, IndexName, PartitionNumber)
);

PRINT 'Sélection des index fragmentés (> ' + CAST(@reorganizeTreshold  AS varchar) + '%)';

-- Selection des index à réorganiser / reconstruire.
WITH IndexesToMaintain AS
(
	SELECT	ips.[object_id],
			ips.index_id,
			AVG(ips.avg_fragmentation_in_percent) AS avg_fragmentation_in_percent,
			COUNT(DISTINCT par.[partition_id]) AS PartitionCount
	FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL , NULL, N'LIMITED') ips
			INNER JOIN sys.partitions AS par ON ips.[object_id] = par.[object_id] AND ips.index_id = par.index_id
	WHERE ips.index_id > 0 AND ips.avg_fragmentation_in_percent > @reorganizeTreshold
	GROUP BY ips.[object_id], ips.index_id
), PartitionDetails AS
(
	SELECT	itm.[object_id],
			itm.index_id,
			ips.partition_number
	FROM IndexesToMaintain itm
			INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL , NULL, N'LIMITED') ips ON itm.[object_id] = ips.[object_id] AND itm.index_id = ips.index_id
	WHERE itm.PartitionCount > 1
)
INSERT INTO @indexInformation
SELECT  OBJECT_SCHEMA_NAME(itm.[object_id]) AS SchemaName,
		OBJECT_NAME(itm.[object_id]) AS TableName,
		idx.[name] AS IndexName,
		IIF(idx.[type] IN (5, 6), 1, 0) AS IsColumnstore,
		ISNULL(idx.[allow_page_locks], 0) AS AllowPageLocks,
		itm.PartitionCount,
		ISNULL(prd.partition_number, -1) AS PartitionNumber,
		itm.avg_fragmentation_in_percent AS Fragementation
FROM IndexesToMaintain itm
		INNER JOIN sys.indexes AS idx ON itm.[object_id] = idx.[object_id] AND itm.index_id = idx.index_id
		LEFT JOIN PartitionDetails prd ON itm.[object_id] = prd.[object_id] AND itm.index_id = prd.index_id;

DECLARE @schemaName sysname;
DECLARE @tableName sysname;
DECLARE @indexName sysname;
DECLARE @isColumnstore bit;
DECLARE @allowPageLocks bit;
DECLARE @partitionNumber int;
DECLARE @partitionCount int;
DECLARE @fragmentation float;
DECLARE @sqlCommand varchar(8000);

DECLARE indexCursor CURSOR FOR 
	SELECT SchemaName, TableName, IndexName, IsColumnstore, AllowPageLocks, PartitionCount, PartitionNumber, Fragementation
	FROM @indexInformation;

OPEN indexCursor;

FETCH NEXT FROM indexCursor
	INTO @schemaName, @tableName, @indexName, @isColumnstore, @allowPageLocks, @partitionNumber, @partitionCount, @fragmentation;

WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT 'Index ' + CAST(@indexName AS varchar) + ' - Table [' +  CAST(@schemaName AS varchar) + '].[' +  CAST(@tableName AS varchar) + '] - Fragmentation ' + CAST(@fragmentation AS varchar) + ' - Page Lock ' + CAST(@allowPageLocks AS varchar) + ' - Partition ' + CAST(@partitionNumber AS varchar) + '/' + CAST(@partitionCount AS varchar);

	SET @sqlCommand = 'ALTER INDEX [' + @indexName + '] ON [' + @schemaName + '].[' + @tableName + '] ';

	IF @fragmentation >= @rebuildTreshold OR @allowPageLocks = 0
	BEGIN
		PRINT 'Reconstruction de l''index ' + CAST(@indexName AS varchar);
		SET @sqlCommand = @sqlCommand + 'REBUILD';
	
	END
	ELSE
	BEGIN
		PRINT 'Reorganisation de l''index ' + CAST(@indexName AS varchar);
		SET @sqlCommand = @sqlCommand + 'REORGANIZE';
	END

	IF @isColumnstore = 1 AND @fragmentation >= @rebuildTreshold
		SET @sqlCommand = @sqlCommand + ' PARTITION = ALL WITH (DATA_COMPRESSION = COLUMNSTORE)';
	ELSE IF @partitionCount > 1
		SET @sqlCommand = @sqlCommand + ' PARTITION = ' + CAST(@partitionNumber AS varchar);

	--PRINT @sqlCommand
	EXEC (@sqlCommand);
	
	FETCH NEXT FROM indexCursor
		INTO @schemaName, @tableName, @indexName, @isColumnstore, @allowPageLocks, @partitionNumber, @partitionCount, @fragmentation;
END

CLOSE indexCursor;
DEALLOCATE indexCursor;

PRINT 'Mise à jour des statistiques de la base ' + CAST(DB_NAME() AS varchar);
EXEC sys.sp_updatestats;
GO