-- Check the indexes fragmentation in your database.
-- Replace <MyDatabase> by your database name.
DECLARE @databaseName sysname = N'<MyDatabase>';
DECLARE @databaseId smallint = DB_ID(@databaseName);
 
DECLARE @reorganizeTreshold numeric(10,7) = 10.0;
DECLARE @rebuildTreshold numeric(10,7) = 25.0;
 
DECLARE @indexesToMaintain AS TABLE
(
	ObjectId					int	NOT NULL,
	IndexId						int	NOT NULL,
	AvgFragmentationInPercent	float NOT NULL,
	PartitionCount				int	NOT NULL,
	UNIQUE CLUSTERED (ObjectId, IndexId, PartitionCount, AvgFragmentationInPercent)
);
 
DECLARE @partitionDetails AS TABLE
(
	ObjectId					int	NOT NULL,
	IndexId						int	NOT NULL,
	PartitionNumber				int	NOT NULL,
	UNIQUE CLUSTERED (ObjectId, IndexId, PartitionNumber)
);
 
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
	IndexAction		varchar(20) not null DEFAULT('None') CHECK(IndexAction IN ('None', 'Rebuild', 'Reorganize')), 
	UNIQUE CLUSTERED (SchemaName, TableName, IndexName, PartitionNumber)
);
INSERT INTO @indexesToMaintain
SELECT	ips.[object_id],
		ips.index_id,
		AVG(ips.avg_fragmentation_in_percent) AS avg_fragmentation_in_percent,
		COUNT(DISTINCT par.[partition_id]) AS PartitionCount
FROM sys.dm_db_index_physical_stats(@databaseId, NULL, NULL , NULL, N'LIMITED') ips
		INNER JOIN sys.partitions AS par ON ips.[object_id] = par.[object_id] AND ips.index_id = par.index_id
WHERE ips.index_id > 0 AND ips.avg_fragmentation_in_percent > @reorganizeTreshold
GROUP BY ips.[object_id], ips.index_id;
 
INSERT INTO @partitionDetails
SELECT	itm.ObjectId,	
		itm.IndexId,
		ips.partition_number
FROM @indexesToMaintain itm
		INNER JOIN sys.dm_db_index_physical_stats(@databaseId, NULL, NULL , NULL, N'LIMITED') ips ON itm.ObjectId = ips.[object_id] AND itm.IndexId = ips.index_id
WHERE itm.PartitionCount > 1
INSERT INTO @indexInformation
SELECT  OBJECT_SCHEMA_NAME(itm.ObjectId) AS SchemaName,
		OBJECT_NAME(itm.ObjectId) AS TableName,
		idx.[name] AS IndexName,
		IIF(idx.[type] IN (5, 6), 1, 0) AS IsColumnstore,
		ISNULL(idx.[allow_page_locks], 0) AS AllowPageLocks,
		itm.PartitionCount,
		ISNULL(prd.PartitionNumber, -1) AS PartitionNumber,
		itm.AvgFragmentationInPercent AS Fragementation,
		IIF(itm.AvgFragmentationInPercent > @rebuildTreshold, 'Rebuild', IIF(itm.AvgFragmentationInPercent > @reorganizeTreshold, 'Reorganize', 'None'))
FROM @indexesToMaintain itm
		INNER JOIN sys.indexes AS idx ON itm.ObjectId = idx.[object_id] AND itm.IndexId = idx.index_id
		LEFT JOIN @partitionDetails prd ON itm.ObjectId = prd.ObjectId AND itm.IndexId = prd.IndexId
WHERE OBJECT_SCHEMA_NAME(itm.ObjectId) <> 'sys';
 
SELECT	ixi.SchemaName,
		ixi.TableName,
		ixi.IndexName,
		ixi.IsColumnstore,
		ixi.AllowPageLocks,
		ixi.PartitionCount,
		ixi.PartitionNumber,
		ixi.Fragementation,
		ixi.IndexAction
FROM @indexInformation ixi;
GO