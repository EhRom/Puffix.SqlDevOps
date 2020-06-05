--https://docs.microsoft.com/en-us/sql/t-sql/statements/create-event-session-transact-sql
--https://docs.microsoft.com/en-us/sql/relational-databases/event-classes/lock-acquired-event-class

--https://sqlperformance.com/2019/02/extended-events/capture-queries-sql-server


-- Création de la session de trace
DECLARE @traceFilePath NVARCHAR(256) = N'd:\MSSQL\TRACES\long_lock'
CREATE EVENT SESSION [long_lock] ON SERVER
	ADD EVENT sqlserver.lock_acquired(SET collect_database_name=(1),collect_resource_description=(1)
	    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_name,sqlserver.is_system,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
	    WHERE ([duration]>=(1000000)))
	ADD TARGET package0.event_file(SET filename=@traceFilePath)
GO

-- Activation de la session de trace
ALTER EVENT SESSION [long_lock] ON SERVER STATE = START;  
GO

-- Désactivation de la session de trace
ALTER EVENT SESSION [long_lock] ON SERVER STATE = STOP;  
GO

-- Suppression de la session de trace
DROP EVENT SESSION [long_lock] ON SERVER;
GO


-- Interprétation
SELECT *, CONVERT(xml, event_data) as xml_data from sys.fn_xe_file_target_read_file('d:\MSSQL\TRACES\long_lock*.xel', null,null,null)