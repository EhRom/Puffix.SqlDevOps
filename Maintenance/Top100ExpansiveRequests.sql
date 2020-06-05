-- Get the top expansive requests in your database.
-- Replace <MyDatabase> by your database name.
-- To reflect your goals, you can update the ORDER BY clause.
USE [<MyDatabase>]
GO

SELECT	TOP (100)
		SUBSTRING(est.[TEXT], 1 + eqs.statement_start_offset / 2, 1 + (IIF(eqs.statement_end_offset = -1, DATALENGTH(est.[TEXT]), eqs.statement_end_offset) - eqs.statement_start_offset) / 2) AS QueryText,
		eqs.execution_count AS ExecutionCount,
		eqs.total_logical_reads AS TotalLogicalReads,
		eqs.last_logical_reads AS LastLogicalReads,
		eqs.total_logical_writes AS TotalLogicalWrites,
		eqs.last_logical_writes AS LastLogicalWrites,
		eqs.total_worker_time AS TotalWorkerTime,
		eqs.last_worker_time AS LastWorkerTime,
		eqs.total_elapsed_time / 1000000 AS TotalElapsedTimeInSecond,
		eqs.last_elapsed_time / 1000000 AS LastElapsedTimeInSecond,
		eqs.last_execution_time AS LastExecutionTime,
		qep.query_plan AS QueryPlan
FROM sys.dm_exec_query_stats eqs
	CROSS APPLY sys.dm_exec_sql_text(eqs.[sql_handle]) est
	CROSS APPLY sys.dm_exec_query_plan(eqs.plan_handle) qep
ORDER BY TotalWorkerTime DESC;
GO