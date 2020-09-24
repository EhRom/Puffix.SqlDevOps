# Actions:
# 1. Decrypt a credential file into a JSON file.
param (
    [Parameter(Mandatory=$true, HelpMessage="Path to file which contains the encrypted credentials.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $encryptedCredentialsPath,

	[Parameter(Mandatory=$true, HelpMessage="Path to file which will contain the decrypted credentials.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $credentialsPath,
	
	[Parameter(Mandatory=$true, HelpMessage="Key (base 64 format) used to read and encrypt the credentials.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $key
)

function DecryptCredentials(
    [string] $encryptedCredentialsPath,
    [string] $credentialsPath,
    [string] $key
) {
    Write-Host "Load the encrypted credentials file content $encryptedCredentialsPath"

    $encryptedFileContent = Get-Content $encryptedCredentialsPath

    Write-Host "Load key"
    [byte[]] $keyContent = [System.Convert]::FromBase64String($key)

    Write-Host "Load the encrypted content to a secure string"
    $secureString = ConvertTo-SecureString -String $encryptedFileContent -Key $keyContent
    $clearCredentialsJsonContent = [System.Net.NetworkCredential]::new('', $secureString).Password

    Write-Host "Save the decrypted content to the file $credentialsPath"
    Out-File -FilePath $credentialsPath -InputObject $clearCredentialsJsonContent
    Write-Host "The credentials are decrypted and available into the file $($credentialsPath)" -Foreground Green
}

DecryptCredentials $encryptedCredentialsPath $credentialsPath $key