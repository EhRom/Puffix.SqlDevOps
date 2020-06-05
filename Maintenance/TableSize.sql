-- Check the table size in your database.
-- Replace <MyDatabase> by your database name.
USE [<MyDatabase>]
GO

SELECT	tbs.[name] AS TableName,
		scm.[name] AS SchemaName,
		prt.rows AS RowCounts,
		SUM(alu.total_pages) * 8 AS TotalSpaceKB, 
		CAST(ROUND(((SUM(alu.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
		SUM(alu.used_pages) * 8 AS UsedSpaceKB, 
		CAST(ROUND(((SUM(alu.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
		(SUM(alu.total_pages) - SUM(alu.used_pages)) * 8 AS UnusedSpaceKB,
		CAST(ROUND(((SUM(alu.total_pages) - SUM(alu.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM sys.tables tbs
		INNER JOIN sys.indexes idx ON tbs.[object_id] = idx.[object_id]
		INNER JOIN sys.partitions prt ON idx.[object_id] = prt.[object_id] AND idx.[index_id] = prt.[index_id]
		INNER JOIN sys.allocation_units alu ON prt.partition_id = alu.container_id
		LEFT OUTER JOIN sys.schemas scm ON tbs.schema_id = scm.schema_id
WHERE	tbs.[name] NOT LIKE 'dt%' AND tbs.is_ms_shipped = 0 AND idx.[object_id] > 255
GROUP BY tbs.[name], scm.[name], prt.Rows
ORDER BY TableName;
GO