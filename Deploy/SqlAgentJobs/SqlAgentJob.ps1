# Actions : 
# 1. create SQL Agent jobs
# 2. drop SQL Agent jobs
param(
	[Parameter(Mandatory=$true,HelpMessage="List of SQL Agent server name.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $sqlJobsServerList,
	
	[Parameter(Mandatory=$true,HelpMessage="Full path for the Jobs configuration.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $sqlJobsConfigurationPath,

	[Parameter(HelpMessage="Specify whether the jobs are installed (true) or dropped.")]
	[bool] $deployJobs = $true
)

# Collection of jobs definition.
Class SqlJobDefinitionCollection {
	[System.Collections.Generic.List[SqlJobDefinition]] $jobs

	SqlJobDefinitionCollection() {
		$this.jobs = New-Object "System.Collections.Generic.List[SqlJobDefinition]"
	}
}

# SQL Agent job definition.
Class SqlJobDefinition {
	[string] $name
	[string] $ownerLoginName
	[string] $targetServerName
	[System.Collections.Generic.List[SqlStepJobDefinition]] $steps
	[System.Collections.Generic.List[SqlScheduleJobDefinition]] $schedules
	[bool] $enabled
	[string] $operatorToMail
	[NotificationLevel] $mailNotificationLevel
	
	SqlJobDefinition([string] $name, [string] $ownerLoginName, [string] $targetServerName, [bool] $enabled) {
		$this.name = $name
		$this.ownerLoginName = $ownerLoginName
		$this.targetServerName = $targetServerName
		$this.steps = New-Object "System.Collections.Generic.List[SqlStepJobDefinition]"
		$this.schedules = New-Object "System.Collections.Generic.List[SqlScheduleJobDefinition]"
		$this.enabled = $enabled

		$this.mailNotificationLevel = [NotificationLevel]::Nothing
	}

	[Microsoft.SqlServer.Management.Smo.Agent.CompletionAction] GetMailNotificationLevelValue() {
		
		if ([NotificationLevel]::JobSuccess -eq $this.mailNotificationLevel) {
			$completionAction = [Microsoft.SqlServer.Management.Smo.Agent.CompletionAction]::OnSuccess
		} elseif ([NotificationLevel]::JobFailure -eq $this.mailNotificationLevel) {
			$completionAction = [Microsoft.SqlServer.Management.Smo.Agent.CompletionAction]::OnFailure
		} elseif ([NotificationLevel]::JobCompletion -eq $this.mailNotificationLevel) {
			$completionAction = [Microsoft.SqlServer.Management.Smo.Agent.CompletionAction]::Always
		} else {
			$completionAction = [Microsoft.SqlServer.Management.Smo.Agent.CompletionAction]::Never
		}

		return $completionAction
	}
}

# Notification level enumeration
Enum NotificationLevel {
	Nothing = 0
	JobSuccess = 1
	JobFailure = 2
	JobCompletion = 3
}

# SQL Agent job step definition.
Class SqlStepJobDefinition {
	[string] $name
	[string] $targetServerName
	[string] $databasename

	[string] $ssisProxyName
	
	[StepCompletionAction] $onSuccessAction
	[int] $onSuccessActionNextStep
	[StepCompletionAction] $onFailAction
	[int] $onFailActionNextStep

	# Private field set by suclasses
	[Microsoft.SqlServer.Management.Smo.Agent.AgentSubSystem] $sqlJobStepSubSystem

	SqlStepJobDefinition() {
		$this.onSuccessActionNextStep = 0
		$this.onFailActionNextStep = 0
	}

	SqlStepJobDefinition([string] $name, [string] $targetServerName, [string] $databasename, [StepCompletionAction] $onSuccessAction, [StepCompletionAction] $onFailAction) {
		$this.name = $name
		$this.targetServerName = $targetServerName
		$this.databasename = $databasename
		$this.onSuccessAction = $onSuccessAction
		$this.onFailAction = $onFailAction

		$this.onSuccessActionNextStep = 0
		$this.onFailActionNextStep = 0
	}

	[void] BaseCreateStep([string] $dbServerName, [Microsoft.SqlServer.Management.Smo.Agent.Job] $sqlJob, [string] $sqlJobStepCommand)
	{		
		################################################################
		# Create SSIS Step
		################################################################
		$sqlJobStep=New-Object Microsoft.SqlServer.Management.Smo.Agent.JobStep($sqlJob, $this.name)
		$sqlJobStep.OnSuccessAction = $this.ConvertStepCompletionAction($this.onSuccessAction)
		$sqlJobStep.OnSuccessStep = $this.onSuccessActionNextStep
		$sqlJobStep.OnFailAction = $this.ConvertStepCompletionAction($this.onFailAction)
		$sqlJobStep.OnFailStep = $this.onFailActionNextStep
		$sqlJobStep.Subsystem=$this.sqlJobStepSubSystem
		$sqlJobStep.Command=$sqlJobStepCommand
		$sqlJobStep.DatabaseName = $this.databasename
		
		if(-Not([String]::IsNullOrEmpty($this.ssisProxyName))) {
			$sqlJobStep.ProxyName = $this.ssisProxyName
		}

		$sqlJobStep.Create()
	}

	[Microsoft.SqlServer.Management.Smo.Agent.StepCompletionAction] ConvertStepCompletionAction($valueToConvert)
	{
		if($valueToConvert -eq [StepCompletionAction]::GoToStep) {
			$convertedValue = [Microsoft.SqlServer.Management.Smo.Agent.StepCompletionAction]::GoToStep
		}
		elseif($valueToConvert -eq [StepCompletionAction]::QuitWithFailure) {
			$convertedValue = [Microsoft.SqlServer.Management.Smo.Agent.StepCompletionAction]::QuitWithFailure
		}
		elseif($valueToConvert -eq [StepCompletionAction]::QuitWithSuccess) {
			$convertedValue = [Microsoft.SqlServer.Management.Smo.Agent.StepCompletionAction]::QuitWithSuccess
		}
		else {
			$convertedValue = [Microsoft.SqlServer.Management.Smo.Agent.StepCompletionAction]::GoToNextStep
		}

		return $convertedValue
	}
}

# Step completion action enumeration
Enum StepCompletionAction {
	GoToNextStep = 0
	QuitWithSuccess = 1
	QuitWithFailure = 2
	GoToStep = 3
}

# SQL Agent job step definition to call SSIS package.
Class SqlSsisStepJobDefinition : SqlStepJobDefinition {
	[string] $type = "SSIS"
	[string] $ssisCatalogName
	[string] $ssisFolderName
	[string] $ssisProjectName
	[string] $ssisPackageName
	[string] $ssisEnvironmentName
	[bool] $ssisIs32bits

	SqlSsisStepJobDefinition()
		: base() {
		$this.sqlJobStepSubSystem = [Microsoft.SqlServer.Management.Smo.Agent.AgentSubSystem]::SSIS
	}

	SqlSsisStepJobDefinition([string] $name, [string] $targetServerName, [string] $databasename, [StepCompletionAction] $onSuccessAction, [StepCompletionAction] $onFailAction)
		: base ($name, $targetServerName, $databasename, $onSuccessAction, $onFailAction) {
		$this.sqlJobStepSubSystem = [Microsoft.SqlServer.Management.Smo.Agent.AgentSubSystem]::SSIS
	}

	[void] CreateStep([string] $dbServerName, [Microsoft.SqlServer.Management.Smo.Agent.Job] $sqlJob) {
		# Get the target server name.
		if([System.String]::IsNullOrEmpty($this.targetServerName)) {
			$targetServerName = $dbServerName
		}
		else {
			$targetServerName = $this.targetServerName
		}

		################################################################
		# Create SSIS Step
		################################################################

		# Build command
		$sqlJobStepCommand = $this.BuildCommand($targetServerName)

		# Create the job step.
		$this.BaseCreateStep($targetServerName, $sqlJob, $sqlJobStepCommand)
	}

	# Get the reference Id to the environment in the SSIS project.
	[string] BuildCommand([string] $targetServerName) {
		# Get reference to the environment
		Write-Host "Get the reference to the environment configuration"

		$ISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"
		[Reflection.Assembly]::LoadWithPartialName($ISNamespace)

		if(!$targetServerName) {
			Throw [System.ArgumentNullException] "The server name is not specified"
		}
		$sqlConnectionString = "Data Source=$targetServerName;Initial Catalog=master;Integrated Security=SSPI"

		# Build connection
		$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
		if(!$sqlConnection) {
			Throw [System.ArgumentException] "Invalid connection (server : $targetServerName)"
		}
		
		# Get SSIS server
		$ssisServer = New-Object Microsoft.SqlServer.Management.IntegrationServices.IntegrationServices $sqlConnection
		if(!$ssisServer) {
			Throw [System.ArgumentException] "Invalid SSIS server (server : $targetServerName)"
		}
		
		# Get the catalog
		$catalogName = $this.ssisCatalogName
		if(!$catalogName) {
			Throw [System.ArgumentNullException] "The catalog name is not specified"
		}
		$ssisCatalog =  $ssisServer.Catalogs[$catalogName]
		if(!$ssisCatalog) {
			Throw [System.ArgumentException] "Invalid SSIS catalog (server : $targetServerName, name : $catalogName)"
		}

		# Get the folder
		$folderName = $this.ssisFolderName
		if(!$folderName) {
			Throw [System.ArgumentNullException] "The folder name is not specified"
		}
		$ssisFolder = $ssisCatalog.Folders[$folderName]
		if(!$ssisFolder) {
			Throw [System.ArgumentException] "Invalid SSIS folder (server : $targetServerName, name : $folderName)"
		}
		
		# Get the project
		$projectName = $this.ssisProjectName
		if(!$projectName) {
			Throw [System.ArgumentNullException] "The project name is not specified"
		}
		$ssisProject = $ssisFolder.Projects[$projectName]
		if(!$ssisProject) {
			Throw [System.ArgumentException] "Invalid SSIS project (server : $targetServerName, name : $projectName)"
		}

		# Get the reference
		$environmentName = $this.ssisEnvironmentName
		if(!$environmentName) {
			Throw [System.ArgumentNullException] "The environment name is not specified"
		}
		$ssisProjectReference = $ssisProject.References[$environmentName, $folderName];
		if(!$ssisProjectReference) {
			Throw [System.ArgumentException] "Invalid SSIS reference (server : $targetServerName, environment : $environmentName, project : $projectName)"
		}
		$projectReferenceId = $ssisProjectReference.ReferenceId

		Write-Host "The reference is found. Value : $projectReferenceId" -ForegroundColor Cyan

		# Get the package name.
		$packageName = $this.ssisPackageName
		if(!$environmentName) {
			Throw [System.ArgumentNullException] "The package name is not specified"
		}
		
		# Build 32 bits mode argument
		if($this.ssisIs32bits) {
			$is32bitsMode = "/X86"
		} else {
			$is32bitsMode = ""
		}

		# Build command
		Write-Host "Build the command to execute in the step"
		$sqlJobStepCommand = "/ISSERVER ""\""\$catalogName\$folderName\$projectName\$packageName\"""" /SERVER ""\""$targetServerName\"""" $is32bitsMode /ENVREFERENCE $projectReferenceId /Par ""\""`$ServerOption::LOGGING_LEVEL(Int16)\"""";1 /Par ""\""`$ServerOption::SYNCHRONIZED(Boolean)\"""";True /CALLERINFO SQLAGENT /REPORTING E"
		
		Write-Host "The command is built : $sqlJobStepCommand" -ForegroundColor Magenta
		
		return $sqlJobStepCommand
	}
}

# SQL Agent job step definition to run TSQL script.
Class SqlTSqlStepJobDefinition : SqlStepJobDefinition {
	[string] $type = "TSQL"
	[string] $command

	SqlTSqlStepJobDefinition()
		: base() {
		$this.sqlJobStepSubSystem = [Microsoft.SqlServer.Management.Smo.Agent.AgentSubSystem]::TransactSql
	}
	
	SqlTSqlStepJobDefinition([string] $name, [string] $targetServerName, [string] $databasename, [StepCompletionAction] $onSuccessAction, [StepCompletionAction] $onFailAction)
		: base ($name, $targetServerName, $databasename, $onSuccessAction, $onFailAction) {
		$this.sqlJobStepSubSystem = [Microsoft.SqlServer.Management.Smo.Agent.AgentSubSystem]::TransactSql
	}

	[void] CreateStep([string] $dbServerName, [Microsoft.SqlServer.Management.Smo.Agent.Job] $sqlJob) {
		# Get the target server name.
		if([System.String]::IsNullOrEmpty($this.targetServerName)) {
			$targetServerName = $dbServerName
		}
		else {
			$targetServerName = $this.targetServerName
		}

		################################################################
		# Create TSQL Step
		################################################################
		# Create the job step.
		$this.BaseCreateStep($targetServerName, $sqlJob, $this.command)
	}
}

# SQL Agent job schedule.
Class SqlScheduleJobDefinition {
	[string] $name
	[bool] $enabled

	SqlScheduleJobDefinition () { }

	SqlScheduleJobDefinition ([string] $name, [bool] $enabled) {
		$this.name = $name
		$this.enabled = $enabled
	}

	[Microsoft.SqlServer.Management.Smo.Agent.JobSchedule] BaseInitSchedule([Microsoft.SqlServer.Management.Smo.Agent.Job] $sqlJob) {
		$sqlJobSchedule = New-Object Microsoft.SqlServer.Management.Smo.Agent.JobSchedule($sqlJob, $this.name)
		$sqlJobSchedule.IsEnabled = $this.enabled

		return $sqlJobSchedule
	}

	[void] BaseCreateSchedule([Microsoft.SqlServer.Management.Smo.Agent.JobSchedule] $sqlJobSchedule) {
		$sqlJobSchedule.Create()
	}
}

# SQL Agent job schedule : Recurring schedule.
Class SqlRecurringScheduleJobDefinition : SqlScheduleJobDefinition {
	[string] $type = "Recurring"
	[RecurringFrequency] $frequency
	[int] $frequencyInterval = 1
	[RecurringSubDayFrequency] $subDayFrequency
	[int] $subDayInterval = 1
	[DateTime] $activeStartDate = [DateTime]::MinValue.Date
	[DateTime] $activeEndDate = [DateTime]::MinValue.Date
	[TimeSpan] $activeStartTime = [TimeSpan]::Parse("00:00:00")
	[TimeSpan] $activeEndTime = [TimeSpan]::Parse("23:59:59")
	[string] $weekDays = "EveryDay"
	[string] $weekDay = "Monday"
	[int] $dayNumberInMonth = 1
	[string] $dayOccurenceInMonth = "First"

	SqlRecurringScheduleJobDefinition () { }

	SqlRecurringScheduleJobDefinition ([string] $name, [bool] $enabled)
		: base($name, $enabled) {
	}

	[void] CreateSchedule([Microsoft.SqlServer.Management.Smo.Agent.Job] $sqlJob) {
		################################################################
		# Create SSIS Schedule
		################################################################
		#https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-schedule-transact-sql
		#https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.agent.jobschedule.aspx
		#https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.agent.jobschedule.frequencyinterval.aspx

		# Init schedule
		$sqlJobSchedule = $this.BaseInitSchedule($sqlJob)		

		if($this.frequency -eq [RecurringFrequency]::Daily) {
			$sqlJobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::Daily
			$sqlJobSchedule.FrequencyInterval = $this.frequencyInterval
		}
		elseif($this.frequency -eq [RecurringFrequency]::Weekly) {
			$sqlJobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::Weekly
			$sqlJobSchedule.FrequencyRecurrenceFactor = $this.frequencyInterval
			$sqlJobSchedule.FrequencyInterval = $this.ExtractWeekDays()
		}
		elseif($this.frequency -eq [RecurringFrequency]::Monthly) {
			$sqlJobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::Monthly
			$sqlJobSchedule.FrequencyRecurrenceFactor = $this.frequencyInterval
			$sqlJobSchedule.FrequencyInterval = $this.dayNumberInMonth
		}
		elseif($this.frequency -eq [RecurringFrequency]::MonthlyRelative) {
			$sqlJobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::MonthlyRelative

			$sqlJobSchedule.FrequencyRecurrenceFactor = $this.frequencyInterval
			$sqlJobSchedule.FrequencyInterval = $this.ExtractWeekDay()
			$sqlJobSchedule.FrequencyRelativeIntervals = $this.ExtractDayOccurenceInMonth()
		}
		else {
			$sqlJobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::Unknown
		}
		
		# Subday frequency
		if($this.subDayFrequency -eq [RecurringSubDayFrequency]::Hour) {
			$sqlJobSchedule.FrequencySubDayTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencySubDayTypes]::Hour
			$sqlJobSchedule.FrequencySubDayInterval = $this.subDayInterval
		}
		elseif($this.subDayFrequency -eq [RecurringSubDayFrequency]::Minute) {
			$sqlJobSchedule.FrequencySubDayTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencySubDayTypes]::Minute
			$sqlJobSchedule.FrequencySubDayInterval = $this.subDayInterval
		}
		elseif($this.subDayFrequency -eq [RecurringSubDayFrequency]::Second) {
			$sqlJobSchedule.FrequencySubDayTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencySubDayTypes]::Second
			$sqlJobSchedule.FrequencySubDayInterval = $this.subDayInterval
		}
		elseif($this.subDayFrequency -eq [RecurringSubDayFrequency]::Once) {
			$sqlJobSchedule.FrequencySubDayTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencySubDayTypes]::Once
		}
		else {
			$sqlJobSchedule.FrequencySubDayTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencySubDayTypes]::Unknown
		}

		$sqlJobSchedule.ActiveStartDate = $this.activeStartDate.Date
		if ($this.activeEndDate -gt [DateTime]::Now) {
			$sqlJobSchedule.ActiveEndDate = $this.activeEndDate.Date
		}
		$sqlJobSchedule.ActiveStartTimeOfDay = $this.activeStartTime
		$sqlJobSchedule.ActiveEndTimeOfDay = $this.activeEndTime

		# Create the job schedule.
		$this.BaseCreateSchedule($sqlJobSchedule)
	}

	[int] ExtractDayOccurenceInMonth() {
		$result = 1
		if($this.dayOccurenceInMonth -eq "First") {
			$result = 1
		}
		elseif($this.dayOccurenceInMonth -eq "Second") {
			$result = 2
		}
		elseif($this.dayOccurenceInMonth -eq "Third") {
			$result = 4
		}
		elseif($this.dayOccurenceInMonth -eq "Fourth") {
			$result = 8
		}
		elseif($this.dayOccurenceInMonth -eq "Last") {
			$result = 16
		}

		return $result
	}

	[int] ExtractWeekDay() {
		$result = 1
		
		if($this.weekDay -eq "Sunday") {
			$result = [int][WeekDay]::Sunday
		}
		elseif($this.weekDay -eq "Monday") {
			$result = [int][WeekDay]::Monday
		}
		elseif($this.weekDay -eq "Tuesday") {
			$result = [int][WeekDay]::Tuesday
		}
		elseif($this.weekDay -eq "Wednesday") {
			$result = [int][WeekDay]::Wednesday
		}
		elseif($this.weekDay -eq "Thursday") {
			$result = [int][WeekDay]::Thursday
		}
		elseif($this.weekDay -eq "Friday") {
			$result = [int][WeekDay]::Friday
		}
		elseif($this.weekDay -eq "Saturday") {
			$result = [int][WeekDay]::Saturday
		}
		elseif($this.weekDay -eq "Day") {
			$result = [int][WeekDay]::Day
		}
		elseif($this.weekDay -eq "WeekDay") {
			$result = [int][WeekDay]::WeekDay
		}
		elseif($this.weekDay -eq "WeekEndDay") {
			$result = [int][WeekDay]::WeekEndDay
		}

		return $result
	}

	[int] ExtractWeekDays() {
		$result = 0
		if ([string]::IsNullOrEmpty($this.weekDays)){
			$result = [int][WeekDays]::EveryDay
		}
		elseif($this.weekDays.Contains("EveryDay")) {
			$result = [int][WeekDays]::EveryDay
		}
		
		if($result -ne [int][WeekDays]::EveryDay -and $this.weekDays.Contains("Sunday")) {
			$result = ($result + [int][WeekDays]::Sunday) % 128
		}
		if($result -ne [int][WeekDays]::EveryDay -and $this.weekDays.Contains("Monday")) {
			$result = ($result + [int][WeekDays]::Monday) % 128
		}
		if($result -ne [int][WeekDays]::EveryDay -and $this.weekDays.Contains("Tuesday")) {
			$result = ($result + [int][WeekDays]::Tuesday) % 128
		}
		if($result -ne [int][WeekDays]::EveryDay -and $this.weekDays.Contains("Wednesday")) {
			$result = ($result + [int][WeekDays]::Wednesday) % 128
		}
		if($result -ne [int][WeekDays]::EveryDay -and $this.weekDays.Contains("Thursday")) {
			$result = ($result + [int][WeekDays]::Thursday) % 128
		}
		if($result -ne [int][WeekDays]::EveryDay -and $this.weekDays.Contains("Friday")) {
			$result = ($result + [int][WeekDays]::Friday) % 128
		}
		if($result -ne [int][WeekDays]::EveryDay -and $this.weekDays.Contains("Saturday")) {
			$result = ($result + [int][WeekDays]::Saturday) % 128
		}
		if($result -ne [int][WeekDays]::EveryDay -and $this.weekDays.Contains("WeekDays")) {
			$result = ($result + [int][WeekDays]::WeekDays) % 128
		}
		if($result -ne [int][WeekDays]::EveryDay -and $this.weekDays.Contains("WeekEnds")) {
			$result = ($result + [int][WeekDays]::WeekEnds) % 128
		}
				
		return $result
	}
}

Enum RecurringFrequency {
	Daily = 0
	Weekly = 1
	Monthly = 2
	MonthlyRelative = 3
	Unknown = 4
}

Enum RecurringSubDayFrequency {
	Hour = 0
	Minute = 1
	Second = 2
	Once = 3
	Unknown = 4
}

Enum WeekDays {
	Sunday = 1
	Monday = 2
	Tuesday = 4
	Wednesday = 8
	Thursday = 16
	Friday = 32
	Saturday = 64
	WeekDays = 62
	WeekEnds = 65
	EveryDay = 127
}

Enum WeekDay {
	Sunday = 1
	Monday = 2
	Tuesday = 3
	Wednesday = 4
	Thursday = 5
	Friday = 6
	Saturday = 7
	Day = 8
	WeekDay = 9
	WeekEndDay = 10
}

# SQL Agent job schedule : One time schedule.
Class SqlOneTimeScheduleJobDefinition : SqlScheduleJobDefinition {
	[string] $type = "OneTime"
	[DateTime] $scheduledDateTime

	SqlOneTimeScheduleJobDefinition () { }

	SqlOneTimeScheduleJobDefinition ([string] $name, [bool] $enabled)
		: base($name, $enabled) {
	}

	[void] CreateSchedule([Microsoft.SqlServer.Management.Smo.Agent.Job] $sqlJob) {
		################################################################
		# Create SSIS Schedule
		################################################################
		
		# Init schedule
		$sqlJobSchedule = $this.BaseInitSchedule($sqlJob)
		$sqlJobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::OneTime

		if(!$this.scheduledDateTime -or $this.scheduledDateTime  -lt [DateTime]::Now) {
			Write-Host "ScheduledDateTime is not valid : $($this.scheduledDateTime). The schedule is past" -ForegroundColor Yellow
		}
		else {
			$sqlJobSchedule.ActiveStartDate = $this.scheduledDateTime.Date
			$sqlJobSchedule.ActiveStartTimeOfDay = $this.scheduledDateTime.TimeOfDay
		}

		# Create the job schedule.
		$this.BaseCreateSchedule($sqlJobSchedule)
	}
}

# SQL Agent job schedule : Agent Starts schedule.
Class SqlAgentStartsScheduleJobDefinition : SqlScheduleJobDefinition {
	[string] $type = "AgentStarts"

	SqlAgentStartsScheduleJobDefinition () { }

	SqlAgentStartsScheduleJobDefinition ([string] $name, [bool] $enabled)
		: base($name, $enabled) {
	}

	[void] CreateSchedule([Microsoft.SqlServer.Management.Smo.Agent.Job] $sqlJob) {
		################################################################
		# Create SSIS Schedule
		################################################################
		
		# Init schedule
		$sqlJobSchedule = $this.BaseInitSchedule($sqlJob)
		$sqlJobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::AutoStart

		# Create the job schedule.
		$this.BaseCreateSchedule($sqlJobSchedule)
	}
}

# SQL Agent job schedule : Idle CPU schedule.
Class SqlIdleCPUScheduleJobDefinition : SqlScheduleJobDefinition {
	[string] $type = "IdleCPU"

	SqlIdleCPUScheduleJobDefinition () { }

	SqlIdleCPUScheduleJobDefinition ([string] $name, [bool] $enabled)
		: base($name, $enabled) {
	}

	[void] CreateSchedule([Microsoft.SqlServer.Management.Smo.Agent.Job] $sqlJob) {
		################################################################
		# Create SSIS Schedule
		################################################################
		
		# Init schedule
		$sqlJobSchedule = $this.BaseInitSchedule($sqlJob)
		$sqlJobSchedule.FrequencyTypes = [Microsoft.SqlServer.Management.Smo.Agent.FrequencyTypes]::OnIdle
		
		# Create the job schedule.
		$this.BaseCreateSchedule($sqlJobSchedule)
	}
}

# Split the server name list into collection
function SplitServerNames([string] $serverNames) {
	[System.Collections.Generic.List[string]] $serverNameCollection = New-Object "System.Collections.Generic.List[string]"
	
	if(![string]::IsNullOrEmpty($serverNames)) {
		$splittedServerNames = $serverNames.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)
		foreach($splittedServerName in $splittedServerNames) {
			$serverNameCollection.Add($splittedServerName.Trim())
		}
	}
	
	return $serverNameCollection
}

# Load SQL Job definitions from JSON file.
function LoadConfiguration(
	[string] $filePath
) {
	Write-Host "Load configuration from $filePath" -ForegroundColor Cyan
	$coreConfig = (Get-Content $filePath | Out-String | ConvertFrom-Json)
	
	$config = New-Object SqlJobDefinitionCollection
	
	foreach($coreJob in $coreConfig.jobs) {
		$enabled = $false

		if(Get-Member -inputobject $coreJob -name "enabled" -Membertype Properties) {
			$enabled = [bool]$coreJob.enabled
		}

		$job = New-Object SqlJobDefinition ($coreJob.name, $coreJob.ownerLoginName, $coreJob.targetServerName, $enabled)

		# Extract mail notification information
		if((Get-Member -inputobject $coreJob -name "operatorToMail" -Membertype Properties) -And `
				(Get-Member -inputobject $coreJob -name "mailNotificationLevel" -Membertype Properties) -And `
				$coreJob.mailNotificationLevel -ne 0) {
			$job.operatorToMail = $coreJob.operatorToMail
			$job.mailNotificationLevel = [NotificationLevel]$coreJob.mailNotificationLevel
		}

		foreach($coreStep in $coreJob.steps) {
			# Extract actions.
			if(Get-Member -inputobject $coreStep -name "onSuccessAction" -Membertype Properties) { 
				$onSuccessAction = [StepCompletionAction]$coreStep.onSuccessAction
			}
			else {
				Write-Host "No onSuccessAction member found" -ForegroundColor Gray
				$onSuccessAction = [StepCompletionAction]::GoToNextStep
			}

			if(Get-Member -inputobject $coreStep -name "onFailAction" -Membertype Properties) {
				$onFailAction = [StepCompletionAction]$coreStep.onFailAction
			}
			else {
				Write-Host "No onFailAction member found" -ForegroundColor Gray
				$onFailAction = [StepCompletionAction]::QuitWithFailure
			}

			# Create step definition.
			if ($coreStep.type -eq "SSIS") {
				$step = New-Object SqlSsisStepJobDefinition($coreStep.name, $coreStep.targetServerName, $coreStep.databasename, [int]$onSuccessAction, [int]$onFailAction)
				$step.ssisCatalogName = $coreStep.ssisCatalogName
				$step.ssisFolderName = $coreStep.ssisFolderName
				$step.ssisProjectName = $coreStep.ssisProjectName
				$step.ssisPackageName = $coreStep.ssisPackageName
				$step.ssisEnvironmentName = $coreStep.ssisEnvironmentName

				if(Get-Member -inputobject $coreStep -name "ssisIs32bits" -Membertype Properties) {
					$step.ssisIs32bits = [bool]$coreStep.ssisIs32bits
				} else {
					$step.ssisIs32bits = $false
				}
			}
			elseif ($coreStep.type -eq "TSQL") {
				$step = New-Object SqlTSqlStepJobDefinition ($coreStep.name, $coreStep.targetServerName, $coreStep.databasename, [int]$onSuccessAction, [int]$onFailAction)
				$step.command = $coreStep.command
			}
			
			if(-Not([String]::IsNullOrEmpty($coreStep.ssisProxyName))) {
				$step.ssisProxyName = $coreStep.ssisProxyName
			}

			# Set Next Step Id if required
			if($onSuccessAction -eq [StepCompletionAction]::GoToStep -and (Get-Member -inputobject $coreStep -name "onSuccessActionNextStep" -Membertype Properties)) {
				$step.onSuccessActionNextStep = [int]$coreStep.onSuccessActionNextStep 
			}
			if($onFailAction -eq [StepCompletionAction]::GoToStep -and (Get-Member -inputobject $coreStep -name "onFailActionNextStep" -Membertype Properties)) {
				$step.onFailAction = [int]$coreStep.onFailActionNextStep
			}
			
			# Add step to the collection		
			if($step) {
				$job.steps.Add($step)
			}
		}
		
		foreach($coreSchedule in $coreJob.schedules) {
			#Extract typed information
			if(Get-Member -inputobject $coreSchedule -name "enabled" -Membertype Properties) { 
				if([string]::Equals($coreSchedule.enabled, "true", [StringComparison]::OrdinalIgnoreCase)) {
					$scheduleEnabled = $true
				}
				else {
					$scheduleEnabled = $false
				}
			}
			else {
				Write-Host "No enabled member found" -ForegroundColor Gray
				$scheduleEnabled = $false
			}

			# Create schedule definition.
			if ($coreSchedule.type -eq "Recurring") {
				$schedule = New-Object SqlRecurringScheduleJobDefinition($coreSchedule.name, [bool]$scheduleEnabled)
				
				if(Get-Member -inputobject $coreSchedule -name "frequency" -Membertype Properties) { 
					if([String]::Equals($coreSchedule.frequency,"Daily", [StringComparison]::OrdinalIgnoreCase)) {
						$schedule.frequency = [RecurringFrequency]::Daily
					}
					elseif([String]::Equals($coreSchedule.frequency,"Weekly", [StringComparison]::OrdinalIgnoreCase)) {
						$schedule.frequency = [RecurringFrequency]::Weekly
					}
					elseif([String]::Equals($coreSchedule.frequency,"Monthly", [StringComparison]::OrdinalIgnoreCase)) {
						$schedule.frequency = [RecurringFrequency]::Monthly
					}
					elseif([String]::Equals($coreSchedule.frequency,"MonthlyRelative", [StringComparison]::OrdinalIgnoreCase)) {
						$schedule.frequency = [RecurringFrequency]::MonthlyRelative
					}
					else {						
						$schedule.frequency = [RecurringFrequency]::Unknown
						Write-Host "No frequency member found." -ForegroundColor Gray
					}
				}
				else {
					$schedule.frequency = [RecurringFrequency]::Unknown
					Write-Host "No frequency member found." -ForegroundColor Gray
				}

				if(Get-Member -inputobject $coreSchedule -name "frequencyInterval" -Membertype Properties) { 
					$schedule.frequencyInterval = [int]$coreSchedule.frequencyInterval
				}
				
				if(Get-Member -inputobject $coreSchedule -name "activeStartDate" -Membertype Properties) { 
					$schedule.activeStartDate = [DateTime]$coreSchedule.activeStartDate
				}
				if(Get-Member -inputobject $coreSchedule -name "activeEndDate" -Membertype Properties) { 
					$schedule.activeEndDate = [DateTime]$coreSchedule.activeEndDate
				}
				if(Get-Member -inputobject $coreSchedule -name "activeStartTime" -Membertype Properties) { 
					$schedule.activeStartTime = [TimeSpan]$coreSchedule.activeStartTime
				}
				if(Get-Member -inputobject $coreSchedule -name "activeEndTime" -Membertype Properties) { 
					$schedule.activeEndTime = [TimeSpan]$coreSchedule.activeEndTime
				}
				
				if(Get-Member -inputobject $coreSchedule -name "weekDays" -Membertype Properties) { 
					$schedule.weekDays = $coreSchedule.weekDays
				}
				if(Get-Member -inputobject $coreSchedule -name "weekDay" -Membertype Properties) { 
					$schedule.weekDay = $coreSchedule.weekDay
				}
				
				if(Get-Member -inputobject $coreSchedule -name "dayOccurenceInMonth" -Membertype Properties) { 
					$schedule.dayOccurenceInMonth = $coreSchedule.dayOccurenceInMonth
				}
				if(Get-Member -inputobject $coreSchedule -name "dayNumberInMonth" -Membertype Properties) { 
					$schedule.dayNumberInMonth = [int]$coreSchedule.dayNumberInMonth
				}
								
				if(Get-Member -inputobject $coreSchedule -name "subDayFrequency" -Membertype Properties) { 
					if([String]::Equals($coreSchedule.subDayfrequency,"Hour", [StringComparison]::OrdinalIgnoreCase)) {
						$schedule.subDayfrequency = [RecurringSubDayFrequency]::Hour
					}
					elseif([String]::Equals($coreSchedule.subDayfrequency,"Minute", [StringComparison]::OrdinalIgnoreCase)) {
						$schedule.subDayfrequency = [RecurringSubDayFrequency]::Minute
					}
					elseif([String]::Equals($coreSchedule.subDayfrequency,"Second", [StringComparison]::OrdinalIgnoreCase)) {
						$schedule.subDayfrequency = [RecurringSubDayFrequency]::Second
					}
					elseif([String]::Equals($coreSchedule.subDayfrequency,"Once", [StringComparison]::OrdinalIgnoreCase)) {
						$schedule.subDayfrequency = [RecurringSubDayFrequency]::Once
					}
					else {						
						$schedule.subDayfrequency = [RecurringSubDayFrequency]::Unknown
					}
				}

				if(Get-Member -inputobject $coreSchedule -name "subDayInterval" -Membertype Properties) { 
						$schedule.subDayInterval = [int]$coreSchedule.subDayInterval
				}
			}
			elseif ($coreSchedule.type -eq "OneTime") {
				$schedule = New-Object SqlOneTimeScheduleJobDefinition($coreSchedule.name, [bool]$scheduleEnabled)

				if(Get-Member -inputobject $coreSchedule -name "scheduledDateTime" -Membertype Properties) { 
					$scheduledDateTime = [DateTime]$coreSchedule.scheduledDateTime
					if($scheduledDateTime -lt [DateTime]::Now) {
						Write-Host "ScheduledDateTime is not valid : $scheduledDateTime. The schedule is past" -ForegroundColor Yellow
					}
					else {
						$schedule.scheduledDateTime = $scheduledDateTime
					}
				}
				else {
					Write-Host "No scheduledDateTime member found." -ForegroundColor Gray
				}
			}
			elseif ($coreSchedule.type -eq "AgentStarts") {
				$schedule = New-Object SqlAgentStartsScheduleJobDefinition($coreSchedule.name, [bool]$scheduleEnabled)
			}
			elseif ($coreSchedule.type -eq "IdleCPU") {
				$schedule = New-Object SqlIdleCPUScheduleJobDefinition($coreSchedule.name, [bool]$scheduleEnabled)
			}

			# Add schedule to the collection		
			if($schedule) {
				$job.schedules.Add($schedule)
			}
		}
		
		$config.jobs.Add($job)
	}
	
	return $config
}

################################################################
# Main function : Deploy jobs
################################################################
function DeployJobs(
	[string] $dbServerName,
	[string] $sqlJobsConfigurationPath
) {
	################################################################
	# Load configuration
	################################################################
	
	Write-Host "Load configuration from path $sqlJobsConfigurationPath"
	$sqlJobsConfiguration = LoadConfiguration ($sqlJobsConfigurationPath)
	
	################################################################
	# Connect to the server.
	################################################################
	Write-Host "Connect to server '$dbServerName'"

    $dbServer = New-Object Microsoft.SqlServer.Management.Smo.Server($dbServerName)
    
    Write-Host "Connected to server $($dbServer.Name) (URN: $($dbServer.Urn) / Etat: $($dbServer.State))"
	
    ################################################################
	# Create the jobs
	################################################################
	foreach($sqlJobConfiguration in $sqlJobsConfiguration.jobs) {
		$sqlJobName = $sqlJobConfiguration.name
		$sqlJobOwnerLoginName = $sqlJobConfiguration.ownerLoginName
		$enabled = $sqlJobConfiguration.enabled
		Write-Host "Create the job $sqlJobName" -ForegroundColor Cyan

		Try {
			$sqlJob = $dbServer.Jobserver.Jobs|where-object {$_.Name -like $sqlJobName}
			
			if (!$sqlJob) {
				Write-Host "The job $sqlJobName does not exists. Create the job."
	
				$sqlJob = New-Object Microsoft.SqlServer.Management.Smo.Agent.Job($dbServer.JobServer, $sqlJobName)
				$sqlJob.Create()
				$sqlJob.IsEnabled = $enabled
				$previousOwnerLoginName = $sqlJob.OwnerLoginName
				$targetServerName = $sqlJob.targetServerName
				if([System.String]::IsNullOrEmpty($targetServerName)) {
					$targetServerName = $dbServerName
				}

				if(-Not([System.String]::IsNullOrEmpty($sqlJobConfiguration.operatorToMail)) -And [NotificationLevel]::Nothing -ne $sqlJobConfiguration.mailNotificationLevel) {
					Write-Host "Check if $($sqlJobConfiguration.operatorToMail) operator exists" -ForegroundColor Gray
					if ($dbServer.JobServer.Operators.Contains($sqlJobConfiguration.operatorToMail)) {
						$sqlOperator = 	$dbServer.JobServer.Operators[$sqlJobConfiguration.operatorToMail]

						Write-Host "Test operator $($sqlOperator.Name) > $($sqlOperator.State) / $($sqlOperator.EmailAddress)" -Foreground Magenta

						$sqlJob.OperatorToEmail = $sqlOperator.Name
						$sqlJob.EmailLevel = $sqlJobConfiguration.GetMailNotificationLevelValue()

					} else {
						Throw "The operator $($sqlJobConfiguration.operatorToMail) does not exists. The job $($sqlJobConfiguration.name) is not created"
					}

					Write-Host "Added operator $($sqlJob.OperatorToEmail) with level $($sqlJob.EmailLevel)" -Foreground Green
				}
				
				if(-Not([System.String]::IsNullOrEmpty($sqlJobOwnerLoginName))) {
					$sqlJob.OwnerLoginName = $sqlJobOwnerLoginName
				}
				
				Write-Host "The job is created. Owner: $($sqlJob.OwnerLoginName) (previous: $($previousOwnerLoginName)). Add steps"

				foreach ($sqlJobStepConfiguration in $sqlJobConfiguration.steps) {
					$sqlJobStepName = $sqlJobStepConfiguration.name
					$sqlJobStepType =  $sqlJobStepConfiguration.type

					Write-Host "Add step $sqlJobStepName ($sqlJobStepType)"
					$sqlJobStepConfiguration.CreateStep($targetServerName, $sqlJob)
					Write-Host "The step $sqlJobStepName ($sqlJobStepType) is added" -ForegroundColor Green
				}

				Write-Host "Steps are created. Add schedules"
				foreach ($sqlJobScheduleConfiguration in $sqlJobConfiguration.schedules) {
					$sqlJobScheduleName = $sqlJobScheduleConfiguration.name
					$sqlJobScheduleType =  $sqlJobScheduleConfiguration.type

					Write-Host "Add step $sqlJobScheduleName ($sqlJobScheduleType)"
					$sqlJobScheduleConfiguration.CreateSchedule($sqlJob)
					Write-Host "The step $sqlJobScheduleName ($sqlJobScheduleType) is added" -ForegroundColor Green
				}
				
				if([System.String]::IsNullOrEmpty($targetServerName)) {
					$targetServerName = "(local)"
				}
		
				Write-Host "Apply configuration for the server '$($targetServerName)'"
				$sqlJob.ApplyToTargetServer($targetServerName)
				$sqlJob.Alter()

				Write-Host "The job $sqlJobName is created" -ForegroundColor Green
			}
			else {
				Write-Host "The job $sqlJobName already exists" -ForegroundColor Yellow
			}
		}
		Catch {
			$errorMessage = $_.Exception.Message
			$failedItem = $_.Exception.ItemName
			Write-Error "Error while creating the job $sqlJobName -> $failedItem : $errorMessage"
		}
	}

	Write-Host "All jobs are created" -ForegroundColor Green
}

################################################################
# Main function : Delete jobs
################################################################
function DropJobs(
	[string] $dbServerName,
	[string] $sqlJobsConfigurationPath
) {
	################################################################
	# Load configuration
	################################################################
	
	Write-Host "Load configuration from path $sqlJobsConfigurationPath"
	$sqlJobsConfiguration = LoadConfiguration ($sqlJobsConfigurationPath)

	################################################################
	# Connect to the server.
	################################################################
	Write-Host "Connect to server '$dbServerName'" -ForegroundColor Cyan

    $dbServer = New-Object Microsoft.SqlServer.Management.Smo.Server($dbServerName)
    
    Write-Host "Connected to server $($dbServer.Name) (URN: $($dbServer.Urn) / Etat: $($dbServer.State))"
	
    ################################################################
	# Drop the jobs
	################################################################
	foreach($sqlJobConfiguration in $sqlJobsConfiguration.jobs) {
		$sqlJobName = $sqlJobConfiguration.name
		Write-Host "Drop the job $sqlJobName"

		Try {
			$sqlJob = $dbServer.Jobserver.Jobs|where-object {$_.Name -like $sqlJobName}
			if ($sqlJob)
			{
				$sqlJob.DropIfExists()
				Write-Host "The job $sqlJobName is dropped" -ForegroundColor Green
			}
			else {
				Write-Host "The job $sqlJobName is already dropped" -ForegroundColor Yellow
			}
		}
		Catch {
			$errorMessage = $_.Exception.Message
			$failedItem = $_.Exception.ItemName
			Write-Error "Error while droppping the job $sqlJobName -> $failedItem : $errorMessage"
		}
	}

	Write-Host "All jobs are dropped" -ForegroundColor Green
}

# Split the list of server to deploy or undeploy jobs on each server.
$sqlJobsServerCollection = SplitServerNames $sqlJobsServerList

# Execute
if($deployJobs) {
	foreach($sqlJobsServerName in $sqlJobsServerCollection) {
		Write-Host "Deploy jobs on server '$($sqlJobsServerName)'." -ForegroundColor Cyan

		DeployJobs $sqlJobsServerName $sqlJobsConfigurationPath
	}
}
else
{
	foreach($sqlJobsServerName in $sqlJobsServerCollection) {
		Write-Host "Undeploy jobs on server '$($sqlJobsServerName)'" -ForegroundColor Cyan
		DropJobs $sqlJobsServerName $sqlJobsConfigurationPath
	}
}

# Configuration sample
#{
#  "jobs": [
#    {
#      "name": "Alter Sample Job",
#      "ownerLoginName": "doe\svc_john",
#      "operatorToMail": "notifyMailOperator",
#      "mailNotificationLevel": 1,
#      "steps": [
#        {
#          "type": "TSQL",
#          "name": "TSQL Step",
#          "onSuccessAction": 1,
#          "onFailAction": 2,
#          "databasename": "MyDatabase",
#          "command": "EXEC [dbo].[sp_MyProcedure]"
#        },
#      "schedules": [
#        {
#          "type": "Recurring",
#          "name": "Recurring Daily Once",
#          "enabled": "true",
#          "frequency": "Daily",
#		   "frequencyInterval": "2",
#		   "subDayFrequency": "Once",
#		   "activeStartDate": "2017-08-07",
#		   "activeEndDate": "2017-08-18",
#          "activeStartTime": "11:23:14"
#        },
#      ]
#    },
#    {
#      "name": "Sample Job",
#      "ownerLoginName": "doe\svc_john",
#      "steps": [
#        {
#          "type": "TSQL",
#          "name": "TSQL Step",
#          "onSuccessAction": 0,
#          "onFailAction": 2,
#          "databasename": "MyDatabase",
#          "command": "EXEC [dbo].[sp_MyProcedure]"
#        },
#        {
#          "type": "SSIS",
#          "name": "SSIS Step 32 bits",
#          "databasename": "master",
#          "onSuccessAction": 0,
#          "onFailAction": 2,
#          "ssisCatalogName": "SSISDB",
#          "ssisFolderName": "MyFolder",
#          "ssisProjectName": "MyProject",
#          "ssisPackageName": "MyPackage.dtsx",
#          "ssisEnvironmentName": "MyEnvironment",
#          "ssisIs32bits": true
#        },
#        {
#          "type": "SSIS",
#          "name": "SSIS Step",
#          "databasename": "master",
#          "onSuccessAction": 1,
#          "onFailAction": 2,
#          "ssisCatalogName": "SSISDB",
#          "ssisFolderName": "MyFolder",
#          "ssisProjectName": "MyProject",
#          "ssisPackageName": "MyPackage2.dtsx",
#          "ssisEnvironmentName": "MyEnvironment"
#        }
#      ],
#      "schedules": [
#        {
#          "type": "Recurring",
#          "name": "Recurring Daily Once",
#          "enabled": "true",
#          "frequency": "Daily",
#		   "frequencyInterval": "2",
#		   "subDayFrequency": "Once",
#		   "activeStartDate": "2017-08-07",
#		   "activeEndDate": "2017-08-18",
#          "activeStartTime": "11:23:14"
#        },
#        {
#          "type": "Recurring",
#          "name": "Recurring Daily Minutly",
#          "enabled": "true",
#          "frequency": "Daily",
#		   "frequencyInterval": "2",
#		   "subDayFrequency": "Minute",
#		   "subDayInterval" : "14",
#		   "activeStartDate": "2017-08-07",
#		   "activeEndDate": "2017-08-18",
#          "activeStartTime": "11:23:14"
#        },
#        {
#          "type": "Recurring",
#          "name": "Recurring Daily Secondly",
#          "enabled": "true",
#          "frequency": "Daily",
#		   "frequencyInterval": "2",
#		   "subDayFrequency": "Second",
#		   "subDayInterval" : "14",
#		   "activeStartDate": "2017-08-07",
#		   "activeEndDate": "2017-08-18"
#        },
#        {
#          "type": "Recurring",
#          "name": "Recurring Weekly Once",
#          "enabled": "true",
#          "frequency": "Weekly",
#		   "frequencyInterval": "2",
#		   "weekDays": "Monday",
#		   "subDayFrequency": "Once",
#		   "activeStartDate": "2017-08-07",
#		   "activeEndDate": "2017-08-18",
#          "activeStartTime": "11:23:14"
#        },
#        {
#          "type": "Recurring",
#          "name": "Recurring Weekly Minutly",
#          "enabled": "true",
#          "frequency": "Weekly",
#		   "weekDays": "Monday,Tuesday,Friday",
#		   "subDayFrequency": "Minute",
#		   "subDayInterval" : "14",
#		   "activeStartDate": "2017-08-07",
#		   "activeEndDate": "2017-08-18",
#          "activeStartTime": "11:23:14"
#        },
#        {
#          "type": "Recurring",
#          "name": "Recurring Monthly Once",
#          "enabled": "true",
#          "frequency": "Monthly",
#		   "frequencyInterval": "2",
#		   "dayNumberInMonth": "11",
#		   "subDayFrequency": "Once",
#		   "activeStartDate": "2017-08-07",
#		   "activeEndDate": "2017-08-18",
#          "activeStartTime": "11:23:14"
#        },
#        {
#          "type": "Recurring",
#          "name": "Recurring MonthlyRelative Once",
#          "enabled": "true",
#          "frequency": "MonthlyRelative",
#		   "dayOccurenceInMonth": "First",
#		   "weekDay": "Thursday",
#		   "frequencyInterval": "6",
#		   "subDayFrequency": "Once",
#		   "activeStartDate": "2017-08-07",
#		   "activeEndDate": "2017-08-18",
#          "activeStartTime": "11:23:14"
#        },
#        {
#          "type": "AgentStarts",
#          "name": "Schedule 2 1",
#          "enabled": "false"
#        },
#        {
#          "type": "IdleCPU",
#          "name": "Schedule 2 2"
#        },
#        {
#          "type": "OneTime",
#          "name": "Schedule 2 2 1",
#          "scheduledDateTime": "2017-08-07T12:00:00"
#        }
#      ]
#    }
#  ]
#}
