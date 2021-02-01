# Actions:
# 1. Encrypt a JSON credential file.
param (
	[Parameter(Mandatory=$true, HelpMessage="Path to file which contains the credentials.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $credentialsPath,
	
    [Parameter(Mandatory=$true, HelpMessage="Path to file which will contain the encrypted credentials.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $encryptedCredentialsPath,

	[Parameter(Mandatory=$true, HelpMessage="Key (base 64 format) used to read and encrypt the credentials.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $key
)

function EncryptCredentials(
    [string] $credentialsPath,
    [string] $encryptedCredentialsPath,
    [string] $key
) {
    Write-Host "Load the credentials file content $credentialsPath"
    $credentialsFileContent = Get-Content -Path $credentialsPath | Out-String
    $coreCredentialsContainer = ConvertFrom-Json $credentialsFileContent

    $jsonContainerContent = ConvertTo-Json $coreCredentialsContainer -Compress

    Write-Host "Encrypt content of the file"
    $secureString = ConvertTo-SecureString -String $jsonContainerContent -AsPlainText -Force
    
    Write-Host "Load key"
    [byte[]] $keyContent = [System.Convert]::FromBase64String($key)

    Write-Host "Save the encrypted content to the file $($encryptedCredentialsPath)"
    ConvertFrom-SecureString -SecureString $secureString -Key $keyContent | Out-File $encryptedCredentialsPath

    Write-Host "The credentials are encrypted into the file $($encryptedCredentialsPath)" -Foreground Green
}

EncryptCredentials $credentialsPath $encryptedCredentialsPath $key