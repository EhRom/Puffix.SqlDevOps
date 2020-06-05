-- Check the indexes size in your database.
-- Replace <MyDatabase> by your database name.
USE [<MyDatabase>]
GO

SELECT	idx.[name] AS IndexName, 
		idx.[type_desc] AS IndexType,
		SUM(pst.[used_page_count]) * 8 AS IndexSizeKB
FROM sys.dm_db_partition_stats AS pst
		INNER JOIN sys.indexes AS idx ON pst.[object_id] = idx.[object_id] AND pst.[index_id] = idx.[index_id]
--WHERE idx.[name] IN ('<List of indexes names if needed>')
GROUP BY idx.[name], idx.[type_desc]
ORDER BY IndexName;
GO
