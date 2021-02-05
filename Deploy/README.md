# Puffix.SqlDevOps

**Puffix.SqlDevOps** is a bunch of scripts used to automate the deployment of BI solutions based on SQL Server. The goal is to deploy the solution without manual action.

These PowerShell scripts are generic and can be resused in many solutions. It can be launched manually or better in your favorite CI/CD solution.
The solution as been tested on Azure Dev Ops and target multiple versions of SQL Server installed on Windows.

You are free to tests these scripts and customize them to target other CI / CD solutions and systems.

## WinRM
* Activate WinRM on your servers: : [ActivateWinRM](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/WinRM/ActivateWinRM.md).

## Manage secrets in deployments
* Powershell sample commands to manage secure strings : [GenerateCredentialsAndSecret](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/GenerateCredentialsAndSecret.md).
* Powershell scripts manual to create encryption keys for secure strings : [CreateKey](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/CreateKey.md).
* Powershell scripts manual to manage credenials : [OpsCredential](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/OpsCredentials.md).

## Deploy SQL package
SQL Database are deployed through [DACPAC packages](https://docs.microsoft.com/en-us/sql/relational-databases/data-tier-applications/data-tier-applications?view=sql-server-ver15).

With Azure Dev Ops, it is advised to use the [SQL Server database deploy](https://github.com/microsoft/azure-pipelines-tasks/blob/master/Tasks/SqlDacpacDeploymentOnMachineGroupV0/README.md) task. You can also write your own script using [SqlPackage.exe utility](https://docs.microsoft.com/en-us/sql/tools/sqlpackage/sqlpackage?view=sql-server-ver15).

## Deploy SSIS packages and configuration
To deploy SSIS packages and configuration, Powershell scripts and Text and JSON configuration files are used. More information: [Deploy SSIS packages and configuration](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Ssis).

## Deploy SQL Agent Jobs
To deploy SQL Agent jobs, Powershell scripts and Text and JSON configuration files are used. More information: [Deploy SQL Agent Jobs](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/SqlAgentJobs) 

## Sample solution
*More to come soon.*


> [Back to root](https://github.com/EhRom/Puffix.SqlDevOps)