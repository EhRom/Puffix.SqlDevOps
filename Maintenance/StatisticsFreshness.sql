-- Check the statistics freshness.
-- Replace <MyDatabase> by your database name.
--USE [<MyDatabase>]
--GO

SELECT	OBJECT_SCHEMA_NAME(stp.[object_id]) AS SchemaName,
		OBJECT_NAME(stp.[object_id]) AS TableName,
		sta.[name] AS StatisticName,
		sta.auto_created AS AutoCreated,
		sta.user_created AS UserCreated,
		sta.no_recompute AS [NoRecompute],
		stp.last_updated AS [LastUpdated],
		stp.[rows] AS [Rows],
		stp.rows_sampled AS RowsSampled,
		ROUND(CAST(stp.rows_sampled AS decimal(10,3)) / CAST(stp.[rows] AS decimal(10,3)) * 100, 3) AS PercentageRowsSampled,
		stp.steps AS Steps,
		stp.unfiltered_rows AS UnfilteredRows,
		stp.modification_counter AS ModificationCounter
FROM sys.stats sta
		CROSS APPLY sys.dm_db_stats_properties(sta.[object_id], sta.stats_id) stp;
GO