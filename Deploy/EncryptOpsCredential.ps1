# Actions:
# 1. Encrypt a JSON credential file.
param (
	[Parameter(Mandatory=$true, HelpMessage="Path to file which contains the credentials.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $credentialsPath,
	
    [Parameter(Mandatory=$true, HelpMessage="Path to file which will contain the encrypted credentials.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $encryptedCredentialsPath,

	[Parameter(Mandatory=$true, HelpMessage="Path to thek key (base 64 format) to use to read the credentials.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $keyPath
)

function LoadKey(
    [string] $keyPath
) {
    [string] $key = $null
    if (-not [string]::IsNullOrEmpty($keyPath)) {
        Write-Host "Load the key from the file '$($keyPath)'" -Foreground Cyan
        $key = Get-Content $keyPath
    } else {
        Write-Host "The key is not specified" -Foreground Yellow
    }
    
    return  [System.Convert]::FromBase64String($key)
}

function EncryptCredentials(
    [string] $credentialsPath,
    [string] $encryptedCredentialsPath,
    [byte[]] $key
) {
    Write-Host "Load the credentials file content $credentialsPath"
    $credentialsFileContent = Get-Content -Path $credentialsPath | Out-String
    $coreCredentialsContainer = ConvertFrom-Json $credentialsFileContent

    $jsonContainerContent = ConvertTo-Json $coreCredentialsContainer -Compress

    Write-Host "Encrypt content of the file"
    $secureString = ConvertTo-SecureString -String $jsonContainerContent -AsPlainText -Force
    # $secureString = ConvertTo-SecureString -String $jsonContainerContent -AsPlainText

    Write-Host "Save the encrypted content to the file $($encryptedCredentialsPath)"
    ConvertFrom-SecureString -SecureString $secureString -Key $key | Out-File $encryptedCredentialsPath

    Write-Host "The credentials are encrypted into the file $($encryptedCredentialsPath)" -Foreground Green
}

[byte[]] $key = LoadKey($keyPath)

EncryptCredentials $credentialsPath $encryptedCredentialsPath $key