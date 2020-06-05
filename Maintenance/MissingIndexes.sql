-- Check the missing indexes in your database.
-- Replace <MyDatabase> by your database name.
-- To reflect your goals, you can update the ORDER BY clause, or customize the TotalUsage calculation.
DECLARE @databaseName sysname = N'<MyDatabase>';
DECLARE @databaseId smallint = DB_ID(@databaseName);

SELECT 	DB_NAME(mid.database_id) AS [DatabaseName],
		OBJECT_SCHEMA_NAME(mid.[object_id]) AS [SchemaName],
		OBJECT_NAME(mid.[object_id]) AS [TableName],
		mis.unique_compiles AS UniqueCompiles,
		mis.user_seeks AS UserSeeks,
		mis.user_scans AS UserScans,
		mis.avg_total_user_cost AS AvgTotalUserCost,
		mis.avg_user_impact AS AvgUserImpact,
		mis.last_user_seek AS LastUserSeek,
		mis.last_user_scan AS LastUserScan,
		mid.equality_columns AS EqualityColumns,
		mid.inequality_columns AS InequalityColumns,
		mid.included_columns AS IncludedColumns,
		mid.[statement] AS [Statement]
FROM sys.dm_db_missing_index_group_stats mis
		INNER JOIN sys.dm_db_missing_index_groups mig on mis.group_handle = mig.index_group_handle
		INNER JOIN sys.dm_db_missing_index_details mid on mig.index_handle = mid.index_handle
WHERE mid.database_id = @databaseId
ORDER BY AvgUserImpact DESC;
GO