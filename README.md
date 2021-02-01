# Puffix.SqlDevOps

Scripts to help the deployement and maintenance of SQL solutions.

## Deploy

Scripts to help the deployement and maintenance of SQL solutions
> [Deploy](https://github.com/EhRom/Puffix.SqlDevOps/tree/master/Deploy)

### Secret management
* Powershell commands to manage secure strings: [GenerateCredentialsAndSecret](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/GenerateCredentialsAndSecret.md).
* Powershell commands to create encryption keys for secure strings: [CreateKey](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/CreateKey.md).
* Powershell commands to manage credenials: [OpsCredential](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/OpsCredentials.md).

### Win RM
* Activate WinRM on your servers: : [ActivateWinRM](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/WinRM/ActivateWinRM.md).

*More to come soon.*

## Maintenance
Some scripts to diagnose performances issues and maintain databases:
* [IndexFragementation](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Maintenance/IndexFragementation.sql) > Check the fragmentation of indexes in a specific database.
* [IndexSize](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Maintenance/IndexSize.sql) > Check the size (in KB) of indexes in a specific database.
* [IndexUsageByDB](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Maintenance/IndexUsageByDB.sql) > Check the use of indexes in a specific database. You can customize the "total index usage metric" to make decisions about deleting or retaining the index.
* [MaintainDb - Script](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Maintenance/MaintainDb%20-%20Script.sql) > Script to manage statistics and indexes in a specific database.
* [MaintainDb - StoredProcedure](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Maintenance/MaintainDb%20-%20StoredProcedure.sql) > Stored procedure to automate the maintenance of statistics and indexes in a database. You can schedule the execution of the procedure via a SQL Agent job.
* [MissingIndexes](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Maintenance/MissingIndexes.sql) > Check the missing indexes in a database, based on the current workload.
* [StatisticsFreshness](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Maintenance/StatisticsFreshness.sql) > Check the freshness of the statistics of a specified database.
* [TableSize](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Maintenance/TableSize.sql) > Check the size (in KB) of tables in a specific database.
* [Top100ExpansiveRequests](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Maintenance/Top100ExpansiveRequests.sql) > Get the top 100 most "expansive" requests in a specific database.
* [Top100ExpansiveStoredProcedures](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Maintenance/Top100ExpansiveStoredProcedures.sql) > Get the top 100 most "expansive" stored procedures in a specific database.
* [TrackLocks](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Maintenance/TrackLocks.sql) > Get information about the locks occuring in a specific database.
