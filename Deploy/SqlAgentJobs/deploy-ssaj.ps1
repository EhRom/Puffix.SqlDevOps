#TIPS :
# Do not put spaces after character : `
param
(
	[Parameter(Mandatory=$true,HelpMessage="Environment name.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $environment
)

# Set settings file.
$settingsFile = [System.IO.Path]::Combine($PSScriptRoot, "..\$environment\settings-$environment.txt")
If (-not (Test-Path $settingsFile))
{
	Write-Output "File not exists : $settingsFile". -foreground Red
	Write-Output "The deployment is canceled". -foreground Yellow
	Exit 0
}

###########################################################################
# LOAD SQL SERVER POWERSHELL MODULE
###########################################################################
Write-Output "Test if SqlServer PowerShell module is installed"
Install-PackageProvider -Name NuGet -Scope CurrentUser -Force

if (-not (Get-Module -ListAvailable -Name SqlServer)) {
	Write-Output "Install the PowerShell module"
	Install-Module SqlServer -Scope CurrentUser -Force -AllowClobber
}

Write-Output "Import the SqlServer PowerShell module"
Import-Module SqlServer

###########################################################################
# READ PARAMETERS
###########################################################################
Write-Output "Load settings file. File : $settingsFile"

Get-Content $settingsFile | `
foreach-object `
	-begin {$settings=@{}} `
	-process { $key = [regex]::split($_,'='); if(($key[0].CompareTo("") -ne 0) -and ($key[0].StartsWith("[") -ne $True)) { $settings.Add($key[0], $key[1]) } }

###########################################################################
# SQL JOBS
###########################################################################
$sqlAgentJobScriptPath = [System.IO.Path]::Combine($PSScriptRoot, "SqlAgentJob.ps1")
$sqlJobsConfigurationFullPath = [System.IO.Path]::Combine($PSScriptRoot, [string]::Format($settings.Get_Item("SqlJobsConfigurationPathPattern"),$environment))

Write-Output "Create SQL Agent jobs"
& $sqlAgentJobScriptPath `
	-sqlJobsServerList "$($env:computername)" `
	-sqlJobsConfigurationPath $sqlJobsConfigurationFullPath `
	-deployJobs $true
