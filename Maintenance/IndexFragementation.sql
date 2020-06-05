-- Check the indexes fragmentation in your database.
-- Replace <MyDatabase> by your database name.
USE [<MyDatabase>]
GO

DECLARE @reorganizeTreshold numeric(10,7) = 5.0;
DECLARE @rebuildTreshold numeric(10,7) = 30.0;

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
SELECT  OBJECT_SCHEMA_NAME(itm.[object_id]) AS SchemaName,
		OBJECT_NAME(itm.[object_id]) AS TableName,
		idx.[name] AS IndexName,
		IIF(idx.[type] IN (5, 6), 1, 0) AS IsColumnstore,
		itm.PartitionCount,
		ISNULL(prd.partition_number, -1) AS PartitionNumber,
		itm.avg_fragmentation_in_percent AS Fragementation
FROM IndexesToMaintain itm
		INNER JOIN sys.indexes AS idx ON itm.[object_id] = idx.[object_id] AND itm.index_id = idx.index_id
		LEFT JOIN PartitionDetails prd ON itm.[object_id] = prd.[object_id] AND itm.index_id = prd.index_id;
GO