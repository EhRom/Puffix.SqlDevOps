-- Check the indexes usage in your database.
-- Replace <MyDatabase> by your database name.
-- To reflect your goals, you can update the ORDER BY clause, or customize the TotalUsage calculation.
DECLARE @databaseName sysname = N'<MyDatabase>';
DECLARE @databaseId smallint = DB_ID(@databaseName);

SELECT	DISTINCT
		OBJECT_SCHEMA_NAME(ius.[object_id]) AS SchemaName,
		OBJECT_NAME(ius.[object_id]) AS TableName,
		idx.name AS IndexName,
		idx.type_desc AS IndexType,
		idx.is_primary_key AS IsPrimaryKey,
		idx.is_unique AS IsUnique,
		ius.user_seeks AS UserSeeks,
		ius.user_scans AS UserScans,
		ius.user_lookups AS UserLookups,
		ius.user_updates AS UserUpdates,
		ius.user_seeks + 2 * ius.user_scans + 4 * ius.user_lookups AS TotalUsage
FROM sys.dm_db_index_usage_stats ius
		INNER JOIN sys.indexes idx ON ius.[object_id] = idx.[object_id] AND ius.[index_id] = idx.[index_id]
		INNER JOIN sys.index_columns idc ON ius.[object_id] = idc.[object_id] AND idc.[index_id] = idx.[index_id]
		INNER JOIN sys.columns clm ON ius.[object_id] = clm.[object_id] AND idc.[column_id] = clm.[column_id]
WHERE ius.[database_id] = @databaseId
ORDER by TotalUsage;
GO