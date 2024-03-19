#TIPS :
# Do not put spaces after character : `
param
(
	[Parameter(Mandatory=$true,HelpMessage="Environment name.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $environment,

	[Parameter(Mandatory=$true,HelpMessage="Key to decrypt secrets.")]
	[string] $secretsKey
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
# READ PARAMETERS
###########################################################################
Write-Output "Load settings file. File : $settingsFile"

Get-Content $settingsFile | `
foreach-object `
	-begin {$settings=@{}} `
	-process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $settings.Add($k[0], $k[1]) } }

###########################################################################
# LOAD CREDENTIALS
###########################################################################
Write-Output "Load credentials"

$decryptOpsCredentialsScriptPath = [System.IO.Path]::Combine($PSScriptRoot, "DecryptOpsCredentials.ps1")
$useOpsCredentialsScriptPath = [System.IO.Path]::Combine($PSScriptRoot, "UseOpsCredentials.ps1")
$encryptedOpsCredentialsFilePath = [System.IO.Path]::Combine($PSScriptRoot, [string]::Format($settings.Get_Item("CredentialsPathPattern"), $environment))
$opsCredentialsFilePath = [System.IO.Path]::Combine($PSScriptRoot, [string]::Format($settings.Get_Item("CredentialsPathPattern"), $environment) + ".json")

& $decryptOpsCredentialsScriptPath `
	-encryptedCredentialsPath $encryptedOpsCredentialsFilePath `
	-credentialsPath $opsCredentialsFilePath `
	-key $secretsKey

& $useOpsCredentialsScriptPath `
	-credentialsPath $opsCredentialsFilePath `
	-key $secretsKey

Remove-Item -Path $opsCredentialsFilePath -Force

###########################################################################
# INTEGRATION SERVICES
###########################################################################
$ssisEnvironmentScriptPath = [System.IO.Path]::Combine($PSScriptRoot, "SsisPackageAndEnvironment.ps1")
$ssisPackageConfigurationFullPath = [System.IO.Path]::Combine($PSScriptRoot, [string]::Format($settings.Get_Item("SsisPackageConfigurationPathPattern"),$environment))


# ODS
$ssisOdsPackageFullPath = [System.IO.Path]::Combine($PSScriptRoot, $settings.Get_Item("SsisOdsPackagePath"))

Write-Output "Deploy SSIS ODS packages"

& $ssisEnvironmentScriptPath `
	-ssisServerName $settings.Get_Item("TargetMainServerName") `
	-ssisCatalogName $settings.Get_Item("SsisCatalogName") `
	-ssisCatalogPassword $settings.Get_Item("SsisCatalogPassword") `
	-ssisFolderName $settings.Get_Item("SsisOdsFolderName") `
	-ssisPackageFullPath $ssisOdsPackageFullPath `
	-ssisProjectName $settings.Get_Item("SsisOdsProjectName") `
	-ssisEnvironmentNames $settings.Get_Item("SsisOdsEnvironmentNames") `
	-ssisPackageConfigurationPath $ssisPackageConfigurationFullPath `
	-credentialsContainer $credentialsContainer `
	-key $secretsKey `
	-deployPackageAndEnvironment $true

# Datawarehouse
$ssisDatawarehousePackageFullPath = [System.IO.Path]::Combine($PSScriptRoot, $settings.Get_Item("SsisDatawarehousePackagePath"))

Write-Output "Deploy SSIS Datawarehouse packages"

& $ssisEnvironmentScriptPath `
	-ssisServerName $settings.Get_Item("TargetMainServerName") `
	-ssisCatalogName $settings.Get_Item("SsisCatalogName") `
	-ssisCatalogPassword $settings.Get_Item("SsisCatalogPassword") `
	-ssisFolderName $settings.Get_Item("SsisDatawarehouseFolderName") `
	-ssisPackageFullPath $ssisDatawarehousePackageFullPath `
	-ssisProjectName $settings.Get_Item("SsisDatawarehouseProjectName") `
	-ssisEnvironmentNames $settings.Get_Item("SsisDatawarehouseEnvironmentNames") `
	-ssisPackageConfigurationPath $ssisPackageConfigurationFullPath `
	-credentialsContainer $credentialsContainer `
	-key $secretsKey `
	-deployPackageAndEnvironment $true

# Datamart
$ssisDatamartPackageFullPath = [System.IO.Path]::Combine($PSScriptRoot, $settings.Get_Item("SsisDatamartPackagePath"))

Write-Output "Deploy SSIS Datamart packages"

& $ssisEnvironmentScriptPath `
	-ssisServerName $settings.Get_Item("TargetMainServerName") `
	-ssisCatalogName $settings.Get_Item("SsisCatalogName") `
	-ssisCatalogPassword $settings.Get_Item("SsisCatalogPassword") `
	-ssisFolderName $settings.Get_Item("SsisDatamartFolderName") `
	-ssisPackageFullPath $ssisDatamartPackageFullPath `
	-ssisProjectName $settings.Get_Item("SsisDatamartProjectName") `
	-ssisEnvironmentNames $settings.Get_Item("SsisDatamartEnvironmentNames") `
	-ssisPackageConfigurationPath $ssisPackageConfigurationFullPath `
	-credentialsContainer $credentialsContainer `
	-key $secretsKey `
	-deployPackageAndEnvironment $true