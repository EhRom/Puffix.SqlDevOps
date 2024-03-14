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
|**enabled**|Indicates whether the job is enabled or not.|boolean|*true* or *false*|
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

The steps are the actions executed by the job. There is two types of steps:

- TSQL script
- SQL Server Integration Services Package

> Note: more types of task exist, but they are not yet implemented in this tool.

Some properties are the same for the two types, and some are specific.

Common properties

|Property|Description|Type|Sample value|
|---|---|:---:|---|
|**name**|Name of the step|string|*1_LoadDataFromOds*|
|**targetServerName**|The server on which to execute the SQL command|string|<ul><li>`localhost`</li><li>`srv11243.mycompny.local`</li></ul>|
|**databasename**|The database on which to execute the SQL command|string|`DWH`|
|**onSuccessAction**|Set the next action when the step succeeds.|enumeration|<ul><li>`0` for `GoToNextStep`</li><li>`1` for `QuitWithSuccess`</li><li>`2` for `QuitWithFailure`</li><li>`3` for `GoToStep`</li></ul>|
|**onSuccessActionNextStep**|Index of the next step when `GoToNextStep` is specified for **onSuccessAction**|int|Integer starting 1|
|**onFailAction**|Set the next action when the step fails.|enumeration|<ul><li>`0` for `GoToNextStep`</li><li>`1` for `QuitWithSuccess`</li><li>`2` for `QuitWithFailure`</li><li>`3` for `GoToStep`</li></ul>|
|**onFailActionNextStep**|Index of the next step when `GoToNextStep` is specified for **onFailAction**|int|Integer starting from 1|

> Retry policies and log policy are not yet implemented.

#### T-SQL step

The T-SQL step is used to execute a SQL script.

The step has only one specific property, the **command** which is the SQL command to run.

Ex:

```json
{
  "type": "TSQL",
  "name": "TSQL Step",
  "onSuccessAction": 1,
  "onFailAction": 2,
  "databasename": "MyDatabase",
  "command": "EXEC [dbo].[sp_MyProcedure]"
},
```

#### SSIS step

The SSIS step is used to execute a SSIS package.

Specific properties:

|Property|Description|Type|Sample value|
|---|---|:---:|---|
|**ssisCatalogName**|Name of the SSIS Catalog to which the package is to be deployed.|string|*SSISDB*|
|**ssisFolderName**|Name / path of the folder to which the package is to be deployed.|string|*SourcesToOds*|
|**ssisProjectName**|Name of the project to which the package is to be deployed.|string|*Customers*|
|**ssisPackageName**|Name of the package to be deployed|string|*TransferCustomersFromCRM*|
|**ssisEnvironmentName**|Name of the environement linked to the package (environments hold the configuration and the secrets)|string|*Local*|
|**ssisIs32bits**|Indicates whether the SSIS runtime use 32 (true), or 64 bits (false)|boolean|*true* or *false*|

Samples:

```json
[
  {
    "type": "SSIS",
    "name": "SSIS Step 32 bits",
    "databasename": "master",
    "onSuccessAction": 0,
    "onFailAction": 2,
    "ssisCatalogName": "SSISDB",
    "ssisFolderName": "MyFolder",
    "ssisProjectName": "MyProject",
    "ssisPackageName": "MyPackage.dtsx",
    "ssisEnvironmentName": "MyEnvironment",
    "ssisIs32bits": true
  },
  {
    "type": "SSIS",
    "name": "SSIS Step",
    "databasename": "master",
    "onSuccessAction": 1,
    "onFailAction": 2,
    "ssisCatalogName": "SSISDB",
    "ssisFolderName": "MyFolder",
    "ssisProjectName": "MyProject",
    "ssisPackageName": "MyPackage2.dtsx",
    "ssisEnvironmentName": "MyEnvironment"
  }
]
```

### Schedule definitions

Schedule definitions define when a job will run. This can be:

- a recurring job,
- a one-time job,
- a job executed when the SQL Agent service starts,
- or a job executed when the CPU is idle.

A job can have several schedules.

The common properties of the jobs are:

|Property|Description|Type|Sample value|
|---|---|:---:|---|
|**type**|Type of the schedule. See each paragraph for details|string|<ul><li>***Recurring***</li><li>***OneTime***</li><li>***AgentStarts***</li><li>***IdleCPU***</li></ul>|
|**name**|Name of the schedule.|string|*Daily*|
|**enabled**|Indicates whether the schedule is enabled or not.|boolean|*true* or *false*|

#### Recurring job schedule

The recurring job schedule properties are:

|Property|Description|Type|Sample value|
|---|---|:---:|---|
|**frequency**|Frequency of the schedule|enumeration|<ul><li>***Daily***: for a daily schedule</li><li>***Weekly***: for a weekly schedule</li><li>***Monthly***: for a monthly schedule</li><li>***MonthlyRelative***: for a monthly relative schedule (e.g. for the first monday of each month, the fourth friday, or the first day)</li><li>***Unknown***</li></ul>|
|**frequencyInterval**|Frequency interval (*occurs every x frequency type*)|int|*1*|
|**subDayFrequency**|Sub-day frequency of the schedule|enumeration|<ul><li>***Hour***: for a hourly (in a day) schedule</li><li>***Minute***: for a minutly (in a day) schedule</li><li>***Second***: for a secondly (in a day) schedule</li><li>***Once***: for a one-time (in a day) schedule</li><li>***Unknown***</li></ul>|
|**subDayInterval**|Sub-day frequency interval (*occurs every y sub-day frequency type*)|int|*4*|
|**activeStartDate**|Activation start date|date|Date at the *yyyy-MM-dd* format. e.g.: *2017-08-18*|
|**activeEndDate**|Activation end date, not set when no end date|date|Date at the *yyyy-MM-dd* format. e.g.: *2017-08-18*|
|**activeStartTime**|Daily activation start time|time|Time at the *HH:mm:ss* format. e.g.: *09:00:00* or *23:30:45*|
|**activeEndTime**|Daily activation end time|time|Time at the *HH:mm:ss* format. e.g.: *09:00:00* or *23:30:45*|
|**weekDays**|Days filter when the frequency is **Weekly**. Multiple days are separated by a comma.|string|<ul><li>***Sunday***</li><li>***Monday***</li><li>***Tuesday***</li><li>***Wednesday***</li><li>***Thursday***</li><li>***Friday***</li><li>***Saturday***</li><li>***WeekDays*** (Monday to Friday)</li><li>***WeekEnds*** (Saturday and Sunday)</li><li>***EveryDay*** (Monday to Sunday)</li></ul><br/>E.g.: `Monday,Tuesday,Friday`, `Thursday`, `WeekDays`, ...|
|**dayNumberInMonth**|Day number when the frequency is **Monthly**|int|E.g.: 11, for an execution each 11th of a month|
|**dayOccurenceInMonth**|Day occurence of the schedule when the frequency is **MonthlyRelative**|enumeration|<ul><li>***First***</li><li>***Second***</li><li>***Third***</li><li>***Fourth***</li><li>***Last***</li></ul>|
|**weekDay**|Linked to *dayOccurenceInMonth*, to set the day of the occurence.|string|<ul><li>***Sunday***</li><li>***Monday***</li><li>***Tuesday***</li><li>***Wednesday***</li><li>***Thursday***</li><li>***Friday***</li><li>***Saturday***</li><li>***Day*** (first day of the month)</li><li>***WeekDay*** (first week day of the month, i.e. Monday to Friday)</li><li>***WeekEndDay*** (first weekend day of the month, i.e. Saturday or Sunday)</li></ul>|

Samples:

```json
[
  {
    "type": "Recurring",
    "name": "Recurring Daily Once",
    "enabled": "true",
    "frequency": "Daily",
    "frequencyInterval": "2",
    "subDayFrequency": "Once",
    "activeStartDate": "2017-08-07",
    "activeEndDate": "2017-08-18",
    "activeStartTime": "11:23:14"
  },
  {
    "type": "Recurring",
    "name": "Recurring Daily Minutly",
    "enabled": "true",
    "frequency": "Daily",
    "frequencyInterval": "2",
    "subDayFrequency": "Minute",
    "subDayInterval" : "14",
    "activeStartDate": "2017-08-07",
    "activeEndDate": "2017-08-18",
    "activeStartTime": "11:23:14"
  },
  {
    "type": "Recurring",
    "name": "Recurring Daily Secondly",
    "enabled": "true",
    "frequency": "Daily",
    "frequencyInterval": "2",
    "subDayFrequency": "Second",
    "subDayInterval" : "14",
    "activeStartDate": "2017-08-07",
    "activeEndDate": "2017-08-18"
  },
  {
    "type": "Recurring",
    "name": "Recurring Weekly Once",
    "enabled": "true",
    "frequency": "Weekly",
    "frequencyInterval": "2",
    "weekDays": "Monday",
    "subDayFrequency": "Once",
    "activeStartDate": "2017-08-07",
    "activeEndDate": "2017-08-18",
    "activeStartTime": "11:23:14"
  },
  {
    "type": "Recurring",
    "name": "Recurring Weekly Minutly",
    "enabled": "true",
    "frequency": "Weekly",
    "weekDays": "Monday,Tuesday,Friday",
    "subDayFrequency": "Minute",
    "subDayInterval" : "14",
    "activeStartDate": "2017-08-07",
    "activeEndDate": "2017-08-18",
    "activeStartTime": "11:23:14"
  },
  {
    "type": "Recurring",
    "name": "Recurring Monthly Once",
    "enabled": "true",
    "frequency": "Monthly",
    "frequencyInterval": "2",
    "dayNumberInMonth": "11",
    "subDayFrequency": "Once",
    "activeStartDate": "2017-08-07",
    "activeEndDate": "2017-08-18",
    "activeStartTime": "11:23:14"
  },
  {
    "type": "Recurring",
    "name": "Recurring MonthlyRelative Once",
    "enabled": "true",
    "frequency": "MonthlyRelative",
    "dayOccurenceInMonth": "First",
    "weekDay": "Thursday",
    "frequencyInterval": "6",
    "subDayFrequency": "Once",
    "activeStartDate": "2017-08-07",
    "activeEndDate": "2017-08-18",
    "activeStartTime": "11:23:14"
  }
]
```

#### One-time job schedule

The one-time job schedule properties are:

|Property|Description|Type|Sample value|
|---|---|:---:|---|
|**scheduledDateTime**|Schedule date and time of the job|datetime|Date at the *yyyy-MM-ddTHH:mm:ss* format. e.g.: *2017-08-18T22:30:45*|

Ex:

```json
{
  "type": "OneTime",
  "name": "Schedule 2 2 1",
  "scheduledDateTime": "2017-08-07T12:00:00"
}
```

#### SQL Agent startup job schedule

The SQL Agent startup job schedule has no specific property.

Ex:

```json
{
  "type": "AgentStarts",
  "name": "Schedule 2 1",
  "enabled": "false"
}
```

#### Idle CPU job schedule

The idle CPU job schedule  has no specific property.

Ex:

```json
{
  "type": "IdleCPU",
  "name": "Schedule 2 2"
}
```

---

[Back to Deploy section](https://github.com/EhRom/Puffix.SqlDevOps/tree/master/Deploy)

[Back to root](https://github.com/EhRom/Puffix.SqlDevOps)
