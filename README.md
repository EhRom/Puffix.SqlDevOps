# Puffix.SqlDevOps

Scripts to help the deployement and maintenance of SQL solutions.

## Deploy
* Powershell commands to manage secure strings : [GenerateCredentialsAndSecret.md](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/GenerateCredentialsAndSecret.md).
* Powershell commands to create encryption keys for secure strings : [CreateKey.md](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/CreateKey.md).
* Powershell commands to manage credenials : [OpsCredential.md](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/OpsCredential.md).

*More to come soon.*

## Maintenance
Some scripts to diagnose performances issues and maintain databases:
* IndexFragementation > Check the fragmentation of indexes in a specific database.
* IndexSize > Check the size (in KB) of indexes in a specific database.
* IndexUsageByDB > Check the use of indexes in a specific database. You can customize the "total index usage metric" to make decisions about deleting or retaining the index.
* MaintainDb - Script > Script to manage statistics and indexes in a specific database.
* MaintainDb - StoredProcedure.sql > Stored procedure to automate the maintenance of statistics and indexes in a database. You can schedule the execution of the procedure via a SQL Agent job.
* MissingIndexes > Check the missing indexes in a database, based on the current workload.
* TableSize > Check the size (in KB) of tables in a specific database.
* Top100ExpansiveRequests > Get the top 100 most "expansive" requests in a specific database.
* Top100ExpansiveStoredProcedures > Get the top 100 most "expansive" stored procedures in a specific database.
* TrackLocks > Get information about the locks occuring in a specific database.
