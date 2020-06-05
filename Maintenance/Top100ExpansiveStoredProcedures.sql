-- Get the top expansive Store Procedure in your database.
-- Replace <MyDatabase> by your database name.
-- To reflect your goals, you can update the ORDER BY clause.
DECLARE @databaseName sysname = N'<MyDatabase>';
DECLARE @databaseId smallint = DB_ID(@databaseName);

SELECT	TOP (100)
		DB_NAME(eps.database_id) AS [DatabaseName],
		OBJECT_SCHEMA_NAME(eps.[object_id]) AS [SchemaName],
		OBJECT_NAME(eps.[object_id]) AS [StoredProcedureName],
		eps.cached_time AS CachedTime, 
		eps.last_execution_time AS LastExecutionTime,
		eps.execution_count AS ExecutionCount,
		eps.total_worker_time AS TotalWorkerTime,
		eps.last_worker_time AS LastWorkerTime,
		eps.min_worker_time AS MinWorkerTime,
		eps.max_worker_time AS MaxWorkerTime,
		eps.total_worker_time / eps.execution_count AS AvgWorkerTime,
		eps.total_elapsed_time AS TotalElapsedTime,
		eps.last_elapsed_time AS LastElapsedTime,
		eps.min_elapsed_time AS MinElapsedTime,
		eps.max_elapsed_time AS MaxElapsedTime,
		eps.total_elapsed_time / eps.execution_count AS AvgElapsedTime,
		eps.total_logical_reads AS TotalLogicalReads,
		eps.last_logical_reads AS LastLogicalReads,
		eps.min_logical_reads AS MinLogicalReads,
		eps.max_logical_reads AS MaxLogicalReads,
		eps.total_logical_reads / eps.execution_count AS AvgLogicalReads,
		eps.total_logical_writes AS TotalLogicalWrites,
		eps.last_logical_writes AS LastLogicalWrites,
		eps.min_logical_writes AS MinLogicalWrites,
		eps.max_logical_writes AS MaxLogicalWrites,
		eps.total_logical_writes / eps.execution_count AS AvgLogicalWrites,
		eps.total_physical_reads AS TotalPhysicalReads,
		eps.last_physical_reads AS LastPhysicalReads,
		eps.min_physical_reads AS MinPhysicalReads,
		eps.max_physical_reads AS MaxPhysicalReads,
		eps.total_physical_reads / eps.execution_count AS AvgPhysicalReads
FROM sys.dm_exec_procedure_stats eps
WHERE DB_NAME(eps.database_id) = @databaseName
ORDER BY AvgWorkerTime DESC;
GO
