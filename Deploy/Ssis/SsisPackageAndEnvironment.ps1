# Actions : 
# 1. deploy a SSIS Project
# 2. uninstall a SSIS Project

param(
	[Parameter(Mandatory=$true,HelpMessage="Database server name.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $ssisServerName,
		
	[Parameter(Mandatory=$true,HelpMessage="Name of the SSIS catalog.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $ssisCatalogName,

	[Parameter(Mandatory=$true,HelpMessage="Password for the SSIS catalog.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $ssisCatalogPassword,

	[Parameter(Mandatory=$true,HelpMessage="Name of the SSIS folder.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $ssisFolderName,
	
	[Parameter(Mandatory=$true,HelpMessage="Full path for the SSIS package.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $ssisPackageFullPath,
	
	[Parameter(Mandatory=$true,HelpMessage="Name of the SSIS project.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $ssisProjectName,
	
	[Parameter(Mandatory=$true,HelpMessage="Name of the SSIS environments deployed.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $ssisEnvironmentNames,
	
	[Parameter(Mandatory=$true,HelpMessage="Full path for the SSIS configuration.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $ssisPackageConfigurationPath,

	[Parameter(HelpMessage="Container of credentials.")]
	[object] $credentialsContainer,

	[Parameter(HelpMessage="Key (base 64 format) used to read and encrypt the credentials.")]
	[string] $key,

	[Parameter(HelpMessage="Specify whether the SSIS package and environments are installed (true) or dropped.")]
	[bool] $deployPackageAndEnvironment = $true
)

	# [Parameter(HelpMessage="Path to file which contains the credentials.")]
	# [string] $credentialsPath,
	
Class ScriptConfiguration {
	
	[System.Collections.Generic.List[ScriptConfigurationElement]] $elements
	
	ScriptConfiguration () 
	{
		$this.elements = New-Object "System.Collections.Generic.List[ScriptConfigurationElement]"
	}
}

Class ScriptConfigurationElement {
	[string] $name
	[string] $description
	[string] $value
	[bool] $isEncryptedValue
	[int] $elementType
	[bool] $isSensitive
	[bool] $addToProject
	[string] $packageList
	[string] $environmentName
	
	ScriptConfigurationElement([string] $name, [string] $description, [string] $value, [bool] $isEncryptedValue, [ConfigurationElementType] $elementType, [bool] $isSensitive, [bool] $addToProject, [string] $packageList, [string] $environmentName) {
		$this.name = $name
		$this.description = $description
		$this.value = $value
		$this.isEncryptedValue = $isEncryptedValue
		$this.elementType = $elementType
		$this.isSensitive = $isSensitive 
		$this.addToProject = $addToProject
		$this.packageList = $packageList
		$this.environmentName = $environmentName
	}
	
	[System.Collections.Generic.List[string]] GetPackageList()
	{
		$extractedPackageList = New-Object "System.Collections.Generic.List[string]"
		
		$extractedPackageListStrings = $this.packageList.Split(@(","), [System.StringSplitOptions]::RemoveEmptyEntries) 
		ForEach ($extractedPackageListString in $extractedPackageListStrings)
		{
			$extractedPackageListString = $extractedPackageListString.Trim()
			$extractedPackageList.Add($extractedPackageListString)
		}

		return $extractedPackageList
	}
	
	[System.TypeCode] GetTypeCode()
	{
		if(!$this.elementType)
		{
			return [System.TypeCode]::String
		}
		if($this.elementType -eq [ConfigurationElementType]::Boolean)
		{
			return [System.TypeCode]::Boolean
		}
		if($this.elementType -eq [ConfigurationElementType]::Byte)
		{
			return [System.TypeCode]::Byte
		}
		if($this.elementType -eq [ConfigurationElementType]::DateTime)
		{
			return [System.TypeCode]::DateTime
		}
		if($this.elementType -eq [ConfigurationElementType]::Decimal)
		{
			return [System.TypeCode]::Decimal
		}
		if($this.elementType -eq [ConfigurationElementType]::Double)
		{
			return [System.TypeCode]::Double
		}
		if($this.elementType -eq [ConfigurationElementType]::Int16)
		{
			return [System.TypeCode]::Int16
		}
		if($this.elementType -eq [ConfigurationElementType]::Int32)
		{
			return [System.TypeCode]::Int32
		}
		if($this.elementType -eq [ConfigurationElementType]::Int64)
		{
			return [System.TypeCode]::Int64
		}
		if($this.elementType -eq [ConfigurationElementType]::SByte)
		{
			return [System.TypeCode]::SByte
		}
		if($this.elementType -eq [ConfigurationElementType]::Single)
		{
			return [System.TypeCode]::Single
		}
		if($this.elementType -eq [ConfigurationElementType]::UInt32)
		{
			return [System.TypeCode]::UInt32
		}
		if($this.elementType -eq [ConfigurationElementType]::UInt64)
		{
			return [System.TypeCode]::UInt64
		}
		
		return [System.TypeCode]::String
	}
	
	[Object] GetTypeValue()
	{
		if(!$this.elementType)
		{
			return $this.value
		}
		if($this.elementType -eq [ConfigurationElementType]::Boolean)
		{
			return [Boolean]$this.value
		}
		if($this.elementType -eq [ConfigurationElementType]::Byte)
		{
			return [Byte]$this.value
		}
		if($this.elementType -eq [ConfigurationElementType]::DateTime)
		{
			return [DateTime]$this.value
		}
		if($this.elementType -eq [ConfigurationElementType]::Decimal)
		{
			return [Decimal]$this.value
		}
		if($this.elementType -eq [ConfigurationElementType]::Double)
		{
			return [Double]$this.value
		}
		if($this.elementType -eq [ConfigurationElementType]::Int16)
		{
			return [Int16]$this.value
		}
		if($this.elementType -eq [ConfigurationElementType]::Int32)
		{
			return [Int32]$this.value
		}
		if($this.elementType -eq [ConfigurationElementType]::Int64)
		{
			return [Int64]$this.value
		}
		if($this.elementType -eq [ConfigurationElementType]::SByte)
		{
			return [SByte]$this.value
		}
		if($this.elementType -eq [ConfigurationElementType]::Single)
		{
			return [Single]$this.value
		}
		if($this.elementType -eq [ConfigurationElementType]::UInt32)
		{
			return [UInt32]$this.value
		}
		if($this.elementType -eq [ConfigurationElementType]::UInt64)
		{
			return [UInt64]$this.value
		}
		
		return $this.value
	}
}

Enum ConfigurationElementType
{
	String = 0
	Boolean = 1
	Byte = 2
	DateTime = 3
	Decimal = 4
	Double = 5
	Int16 = 6
	Int32 = 7
	Int64 = 8
	SByte = 9
	Single = 10
	UInt32 = 11
	UInt64 = 12
}

function LoadConfiguration(
	[string] $filePath
)
{
	$coreConfig = (Get-Content $filePath | Out-String | ConvertFrom-Json)
	
	$config = New-Object ScriptConfiguration
	foreach($coreConfigElement in $coreConfig.elements)
	{
		if(!$coreConfigElement.isEncryptedValue)
		{
			$configIsEncryptedValue = $false
		}
		else
		{
			$configIsEncryptedValue = $coreConfigElement.isEncryptedValue
		}
		
		if(!$coreConfigElement.elementType)
		{
			$configElementType = [ConfigurationElementType]::String
		}
		else
		{
			$configElementType = $coreConfigElement.elementType
		}
		
		if(!$coreConfigElement.isSensitive)
		{
			$configIsSensitive = $false
		}
		else
		{
			$configIsSensitive = $coreConfigElement.isSensitive
		}

		if(!$coreConfigElement.environmentName)
		{
			$configEnvironmentName = ""
		}
		else
		{
			$configEnvironmentName = $coreConfigElement.environmentName
		}
		
		$configElement = New-Object ScriptConfigurationElement($coreConfigElement.name, $coreConfigElement.description, $coreConfigElement.value, $configIsEncryptedValue, $configElementType, $configIsSensitive, $coreConfigElement.addToProject, $coreConfigElement.packageList, $configEnvironmentName)
		
		$config.elements.Add($configElement)
	}
	
	return $config
}

function SaveConfiguration(
	[string] $filePath,
	[ScriptConfiguration] $config
)
{ 
	Invoke-Command -scriptblock {
		$config | ConvertTo-Json | Out-File $filePath
	}
}

function DisplayConfiguration (
	[ScriptConfiguration]$ssisPackageConfiguration
)
{
	Write-Output "Display configuration"
	foreach($element in $ssisPackageConfiguration.elements)
	{
		$elementName = $element.name
		$elementValue = $element.GetTypeValue()
		$elementValueType = $elementValue.GetType()
		Write-Output "$elementName -> $elementValue ($elementValueType)"	
	}
}

function SplitEnvironmentNames([string] $ssisEnvironmentNames) {
	[System.Collections.Generic.List[string]] $ssisEnvironmentNameCollection = New-Object "System.Collections.Generic.List[string]"
	
	if(![string]::IsNullOrEmpty($ssisEnvironmentNames))
	{
		$splittedEnvironmentNames = $ssisEnvironmentNames.Split("|", [System.StringSplitOptions]::RemoveEmptyEntries)
		foreach($splittedEnvironmentName in $splittedEnvironmentNames)
		{
			$ssisEnvironmentNameCollection.Add($splittedEnvironmentName.Trim())
		}
	}
	
	return $ssisEnvironmentNameCollection
}

################################################################
# Main function : deploy
################################################################
function DeployPackageAndEnvironment(
	[string] $ssisServerName,
	[string] $ssisCatalogName,
	[string] $ssisCatalogPassword,
	[string] $ssisFolderName,
	[string] $ssisPackageFullPath,
	[string] $ssisProjectName,
	[string] $ssisEnvironmentNames,
	[string] $ssisPackageConfigurationPath,
	[object] $credentialsContainer,
	[string] $key
) {
	################################################################
	# Load configuration
	################################################################
	Write-Host "Load configuration from path $ssisPackageConfigurationPath"
	$ssisPackageConfiguration = LoadConfiguration ($ssisPackageConfigurationPath)
	
	################################################################
	# Load the IntegrationServices Assembly
	################################################################
	$ISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"

	Write-Host "Load Integration Services libraries"
	[Reflection.Assembly]::LoadWithPartialName($ISNamespace)
		
	################################################################
	# Connect to the server.
	################################################################
	Write-Host "Connect to server '$ssisServerName'" -ForegroundColor Cyan

	$sqlConnectionString = "Data Source=$ssisServerName;Initial Catalog=master;Integrated Security=SSPI"
	$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString	

	################################################################
	# Connect to integration services.
	################################################################
	# Connect to Integration Service
	Write-Host "Connect to Integration Service"  -ForegroundColor Cyan
	$ssisServer = New-Object Microsoft.SqlServer.Management.IntegrationServices.IntegrationServices $sqlConnection
	Write-Host "The connection to Integration Service is up."  -ForegroundColor Green
	
	################################################################
	# Load SSIS catalog.
	################################################################
	#Get the catalog, or create if not exists.
	$ssisCatalog =  $ssisServer.Catalogs[$ssisCatalogName]
	if(!$ssisCatalog) {
		Write-Host "Create the catalog $ssisCatalogName." -ForegroundColor Cyan

		if ($null -ne $credentialsContainer) {
			$opsCredential = $credentialsContainer.GetCredential($ssisCatalogPassword)
			$ssisCatalogClearPassword = $opsCredential.GetPasswordClear($key)			
		} else {
			$ssisCatalogClearPassword = $ssisCatalogPassword
		}

		Try {
			(New-Object Microsoft.SqlServer.Management.IntegrationServices.Catalog($ssisServer, $ssisCatalogName, $ssisCatalogClearPassword)).Create()
			$ssisCatalog =  $ssisServer.Catalogs[$ssisCatalogName]
			Write-Host "The catalog $ssisCatalogName is created." -ForegroundColor Green
		} Catch {
			$errorMessage = $_.Exception.Message
			$failedItem = $_.Exception.ItemName
			Write-Error "Error while creating the SSIS catalog $ssisCatalogName -> $failedItem : $errorMessage"
			exit 0
		} Finally {
			$ssisCatalogClearPassword = $null
		}
	}
	else {
		Write-Host "The catalog $ssisCatalogName is loaded."
	}
	
	################################################################
	# Load or create SSIS folder.
	################################################################
	#Get the folder to deploy the packages
	$ssisFolder = $ssisCatalog.Folders[$ssisFolderName]

	#Create the folder if not exists
	if (!$ssisFolder) {
		Write-Host "Create the folder $ssisFolderName." -Foreground Cyan
			
		$ssisFolder = New-Object "$ISNamespace.CatalogFolder" ($ssisCatalog, $ssisFolderName, $ssisFolderName)            
		$ssisFolder.Create()  
		
		Write-Host "The folder $ssisFolderName is created." -Foreground Green
	}
	else {
		Write-Host "The folder  $ssisFolderName already exists."
	}
	
	################################################################
	# Project deployement.
	################################################################
	Write-Host "Deploy the project $ssisProjectName. Package $($ssisPackageFullPath)" -Foreground Cyan
	
	[byte[]] $ssisProjectFile = [System.IO.File]::ReadAllBytes($ssisPackageFullPath)
	$ssisFolder.DeployProject($ssisProjectName, $ssisProjectFile)

	Write-Host "The project $ssisProjectName is deployed." -Foreground Green
	
	################################################################
	# Load project.
	################################################################
	$ssisProject = $ssisFolder.Projects[$ssisProjectName]
	if (!$ssisProject) {
		Write-Error "The project $ssisProjectName does not exist."
		Exit 0
	}
	else {
		Write-Host "The project $ssisProjectName is loaded." -Foreground Green
	}
	
	################################################################
	# Load environments.
	################################################################
	# Split environments Names, and select SSIS references.
	$ssisEnvironmentNameCollection = SplitEnvironmentNames $ssisEnvironmentNames
	
	foreach($ssisEnvironmentName in $ssisEnvironmentNameCollection) {
		$ssisEnvironment = $ssisFolder.Environments[$ssisEnvironmentName]

		if (!$ssisEnvironment) {
			Write-Host "Create the environment $ssisEnvironmentName." -Foreground Cyan
			
			$ssisEnvironment = New-Object "$ISNamespace.EnvironmentInfo" ($ssisFolder, $ssisEnvironmentName, $ssisEnvironmentName)
			$ssisEnvironment.Create()  
		
			Write-Host "The environment $ssisEnvironmentName is created." -Foreground Green
		}
		else {
			Write-Host "The environment $ssisEnvironmentName is loaded."
		}
	
		################################################################
		# Load reference to the environment.
		################################################################
		$ssisReference = $ssisProject.References[$ssisEnvironmentName, $ssisFolder.Name]
		if (!$ssisReference) {
			#Making project refer to this environment
			Write-Host "Add the reference between the project $ssisProjectName and the environment $ssisEnvironmentName." -Foreground Cyan
		
			$ssisProject.References.Add($ssisEnvironmentName, $ssisFolder.Name)
			$ssisProject.Alter() 
			
			Write-Host "The reference between the project $ssisProjectName and the environment $ssisEnvironmentName is added." -Foreground Green
		}
		else {
			Write-Host "The reference between the project $ssisProjectName and the environment $ssisEnvironmentName is loaded."
		}
	
		################################################################
		# Load environment configuration.
		################################################################
		Write-Host "Deploy configuration" -Foreground Cyan
		foreach($ssisConfigurationElement in $ssisPackageConfiguration.elements)
		{
			if ([string]::IsNullOrEmpty($ssisConfigurationElement.environmentName) -or [string]::Equals($ssisEnvironmentName, $ssisConfigurationElement.environmentName))
			{
				$configElementName = $ssisConfigurationElement.name
		
				$ssisParameter = $ssisEnvironment.Variables[$configElementName];
		
				if (!$ssisParameter)
				{
					Write-Host "Adding environment variable $configElementName (Encrypted: $($ssisConfigurationElement.isEncryptedValue) / Sensitive: $($ssisConfigurationElement.isSensitive))" -Foreground Magenta
					if($ssisConfigurationElement.isEncryptedValue -and $credentialsContainer -ne $null) {
						$opsCredential = $credentialsContainer.GetCredential($ssisConfigurationElement.value)
						$ssisConfigurationElementValue = $opsCredential.GetPasswordClear($key)
					} else {
						$ssisConfigurationElementValue = $ssisConfigurationElement.value
					}
					
					$ssisEnvironment.Variables.Add($configElementName, $ssisConfigurationElement.GetTypeCode(), $ssisConfigurationElementValue, $ssisConfigurationElement.isSensitive, $ssisConfigurationElement.description)
					$ssisEnvironment.Alter()
			
					# Retrieve added parameter
					$ssisParameter = $ssisEnvironment.Variables[$configElementName]
			
					Write-Host "Environment variable $configElementName is added" -Foreground Green
				}
				else {
					Write-Host "Environment variable $configElementName already exists"
				}
		
				# Associate parameter with project.
				if ($ssisConfigurationElement.addToProject)
				{
					Write-Host "Associate $configElementName with project $ssisProjectName"
			
					$ssisProjectParameter = $ssisProject.Parameters[$configElementName]
					if($ssisProjectParameter) {
						Write-Host "Associate the parameter $configElementName with the project $ssisProjectName"
				
						$ssisProjectParameter.Set([Microsoft.SqlServer.Management.IntegrationServices.ParameterInfo+ParameterValueType]::Referenced, $ssisParameter.Name)            
						$ssisProject.Alter()
				
						Write-Host "The parameter $configElementName is associated with the project $ssisProjectName" -Foreground Cyan
					}
					else
					{
						Write-Host "The parameter $configElementName does not exists in project $ssisProjectName"
					}
				}

				# Associate parameter with Packages.
				Write-Host "Associate $configElementName with packages"
				foreach($currentPackageName in $ssisConfigurationElement.GetPackageList())
				{
					Write-Host "Associate $configElementName with package $currentPackageName"
					$ssisPackage = $ssisProject.Packages[$currentPackageName]
					if($ssisPackage)
					{
						$ssisPackageParameter = $ssisPackage.Parameters[$configElementName]
						if($ssisPackageParameter)
						{
							Write-Host "Associate the parameter $configElementName with the package $ssisProjectName / $currentPackageName"
					
							$ssisPackageParameter.Set([Microsoft.SqlServer.Management.IntegrationServices.ParameterInfo+ParameterValueType]::Referenced, $ssisParameter.Name)            
							$package.Alter()
					
							Write-Host "The parameter $configElementName is associated with the package $ssisProjectName / $currentPackageName"
						}
						else
						{
							Write-Host "The parameter $configElementName does not exists in Package $ssisProjectName / $currentPackageName" #-foreground yellow
						}
					}
					else
					{
						Write-Host "The package $currentPackageName does not exists in project $ssisProjectName" #-foreground yellow
					}
				}
			}
		}
	}
	
	Write-Host "Configuration deployed for $ssisEnvironmentNames environements" -Foreground Green
}

################################################################
# Main function: undeploy
################################################################
function UndeployPackageAndEnvironment(
	[string] $ssisServerName,
	[string] $ssisCatalogName,
	[string] $ssisFolderName,
	[string] $ssisProjectName,
	[string] $ssisEnvironmentNames
) {
	################################################################
	# Load the IntegrationServices Assembly
	################################################################
	$ISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"

	Write-Host "Load Integration Services libraries"
	[Reflection.Assembly]::LoadWithPartialName($ISNamespace)
	
	################################################################
	# Connect to the server.
	################################################################
	Write-Host "Connect to server '$ssisServerName'" -Foreground Cyan

	$sqlConnectionString = "Data Source=$ssisServerName;Initial Catalog=master;Integrated Security=SSPI"
	$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString	
	
	################################################################
	# Connect to integration services.
	################################################################
	Write-Host "Connect to Integration Service"

	$ssisServer = New-Object Microsoft.SqlServer.Management.IntegrationServices.IntegrationServices $sqlConnection
	Write-Host "The connection to Integration Service is up." -Foreground Green
	
	################################################################
	# Load SSIS catalog.
	################################################################
	# Get the catalog.
	$ssisCatalog =  $ssisServer.Catalogs[$ssisCatalogName]
	if(!$ssisCatalog)
	{
		Write-Host "The catalog $ssisCatalogName does not exist. Nothing to undeploy."
		return
	}
	else
	{
		Write-Output "The catalog $ssisCatalogName is loaded."
	}
	
	################################################################
	# Load SSIS folder.
	################################################################
	# Get the folder.
	$ssisFolder = $ssisCatalog.Folders[$ssisFolderName]
	if (!$ssisFolder)
	{
		Write-Host "The folder $ssisFolderName does not exist. Nothing to undeploy."
		return
	}
	else
	{
		Write-Host "The folder  $ssisFolderName is loaded."
	}
	
	################################################################
	# Load and delete project.
	################################################################
	$ssisProject = $ssisFolder.Projects[$ssisProjectName]
	if ($ssisProject)
	{
		Write-Host "Deleting the project $ssisProjectName." -Foreground Cyan
		$ssisProject.Drop()
		Write-Host "The project $ssisProjectName is deleted." -Foreground Green
	}
	else
	{
		Write-Output "The project $ssisProjectName is already deleted." #-foreground yellow
	}

	Write-Host "The project $ssisProjectName is undeployed." -Foreground Green
	
	Write-Host ""
	
	################################################################
	# Load and delete environment.
	################################################################
	# Split environments Names
	$ssisEnvironmentNameCollection = SplitEnvironmentNames $ssisEnvironmentNames

	foreach($ssisEnvironmentName in $ssisEnvironmentNameCollection)
	{
		$ssisEnvironment = $ssisFolder.Environments[$ssisEnvironmentName]
		if ($ssisEnvironment)
		{
			Write-Host "Deleting the environment $ssisEnvironmentName." -Foreground Cyan
			$ssisEnvironment.Drop()		
			Write-Host "The environment $ssisEnvironmentName is deleted." -Foreground Green
		}
		else
		{
			Write-Host "The environment $ssisEnvironmentName is already deleted." -Foreground Yellow
		}
	}
}

# Execute
if($deployPackageAndEnvironment)
{
	Write-Host "Deploy package and environement" -Foreground Cyan
	DeployPackageAndEnvironment $ssisServerName $ssisCatalogName $ssisCatalogPassword $ssisFolderName $ssisPackageFullPath $ssisProjectName $ssisEnvironmentNames $ssisPackageConfigurationPath $credentialsContainer $key
}
else
{
	Write-Host "Undeploy package and environement" -Foreground Cyan
	UndeployPackageAndEnvironment $ssisServerName $ssisCatalogName $ssisFolderName $ssisProjectName $ssisEnvironmentNames
}

# Configuration sample
#{
#  "elements": [
#    {
#      "name": "MyParameter",
#      "description": "",
#      "value": "myValue",
#      "elementType": 7,
#      "addToProject": true,
#      "packageList": ""
#    },
#    {
#      "name": "MyParameter_Spec",
#      "description": "",
#      "value": "myValue_1",
#      "elementType": 7,
#      "addToProject": true,
#      "packageList": "",
#      "environmentName": "MyEnvironment_1"
#    },
#    {
#      "name": "MyParameter_Spec",
#      "description": "",
#      "value": "myValue_2",
#      "elementType": 7,
#      "addToProject": true,
#      "packageList": "",
#      "environmentName": "MyEnvironment_2"
#    }
#  ]
#}
