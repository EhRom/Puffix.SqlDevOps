# Deploy SQL Agent Jobs

The goal of these scripts is to deploy SQL Agent job without manual action.

> Note: with Powershell restrictions policies, you may need to copy and paste the content of the files in a new file.

## Script files

The following file tree is expected on the deployment machine in order to be able to run the scripts:

```text
| - <root>
|  | - Scripts
|  |  | - SqlAgentJob.ps1
|  |  | - deploy-ssaj.ps1
|  |  | - undeploy-ssaj.ps1
|  | - <env 1>
|  |  | - settings-<env 1>.txt
|  |  | - sqljobs-<env 1>.json
|  | - <env 2>
|  |  | - settings-<env 2>.txt
|  |  | - sqljobs-<env 2>.json
```

## SqlAgentJob.ps1 script

The `SqlAgentJob.ps1` script is the core library for dpeloying SQL Agent jobs on your server.

## deploy-ssaj.ps1 script

The `deploy-ssaj.ps1` is the script to **deploy** the SQL Agent jobs definitions. The script takes the environment name as argument. It relies on the previous file tree, and the configuration files (`settings-<env>.txt` & `sqljobs-<env>.json`)to deploy the SQL Agent jobs.

```powershell
.\deploy-ssaj.ps1 '<env>'
```

## undeploy-ssaj.ps1 script

The `undeploy-ssaj.ps1` is the script to **undeploy** the SQL Agent jobs definitions. The script takes the environment name as argument. It relies on the previous file tree, and the configuration files (`settings-<env>.txt` & `sqljobs-<env>.json`) to undeploy the SQL Agent jobs.

```powershell
.\undeploy-ssaj.ps1 '<env>'
```

## settings-\<env\>.txt file

The `settings-<env>.txt` contains the definition of the environment to deploy, with the two parameters:

```text
[General]
Version=<Version number>

[SQLJobs]
SqlJobsConfigurationPathPattern=..\{0}\sqljobs-{0}.json
```

|Parameter|Description|
|---|---|
|Version|Informative version number of the solution|
|SqlJobsConfigurationPathPattern|File path pattern to get the sqljobs definition file.|

> The file can be copied as is if the there is no need to customize the file tree. Otherwise, update all the `settings-<env>.txt`, `deploy-ssaj.ps1` and `undeploy-ssaj.ps1` files.

## sqljobs-\<env\>.json file

The `sqljobs-<env>.json` file contains the definition of the SQL Agent jobs.

### Jobs definition

Jobs are the root objects of the JSON configuration file. A job is defined by the following properties:

|Property|Description|Type|Sample value|
|---|---|:---:|---|
|**name**|Name of the SQL Agent Job|*ODStoDWH (Prod)*|
|**ownerLoginName**|Account that runs SQL Agent|string|<ul><li>`<network short name>\<account short name>`</li><li>`NT SERVICE\SQLSERVERAGENT`</li></ul>|
|**targetServerName**|Name FQDN of the SQL Server|string|<ul><li>`localhost`</li><li>`srv11243.mycompny.local`</li></ul>|
|**enabled**|Indicates whether the job is enabled or not. |boolean|*true* or *false*|
|**steps**|List of steps that define the job. See the [steps](#steps-definition) paragraph|list of objects|cf. [steps](#steps-definition) paragraph|
|**schedules**|List of job schedules. See the [schedules](#schedules-definition) paragraph|list of objects|cf. [schedules](#schedules-definition) paragraph|

Sample:

```json
{
  "jobs": [
    {
      "name": "<Name of the SQL Agent Job>",
      "ownerLoginName": "<Account that runs SQL Agent (e.g. <network short name>\\<account short name>>, NT SERVICE\\SQLSERVERAGENT, ...)",
      "targetServerName": "<Name FQDN of the SQL Server>",
      "enabled": true,
      "steps": [
        //...
      ],
      "schedules": [
        //...
      ]
    }
  ]
}
```

### Steps definition

*More to come soon.*

### Schedules definition

*More to come soon.*

[Back to Deploy section](https://github.com/EhRom/Puffix.SqlDevOps/tree/master/Deploy)

[Back to root](https://github.com/EhRom/Puffix.SqlDevOps)
