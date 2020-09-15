# Actions : generate a key from a passphrase.
param (
	[Parameter(Mandatory=$true,HelpMessage="Passphrase used to generate the key. It must be secured and secret.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $passphrase,
		
	[Parameter(HelpMessage="Path of the file to store the key. If not specified, the key is only displayed.")]
	[string] $outFilePath,

    [Parameter(HelpMessage="Specify whether the key is displayed in the console or not. If the file path is not specified, the key will anyway be displayed.")]
	[bool] $displayKey = $true
)

function GenerateKey (
    [string] $passphrase,
    [string] $outFilePath,
    [bool] $displayKey
) {
    Write-Host "Generate key from a passphrase"

    $encoding = [System.Text.Encoding]::Unicode
    $sha256 = New-Object System.Security.Cryptography.SHA256CryptoServiceProvider 

    $passphraseBytes = $encoding.GetBytes($passphrase)
    $key = $sha256.ComputeHash($passphraseBytes)
    $base64Key = [System.Convert]::ToBase64String($key)

    Write-Host "The key is generated" -Foreground Green

    if (-not [string]::IsNullOrEmpty($outFilePath)) {
        Out-File -FilePath $outFilePath -InputObject $base64Key
        
        Write-Host "The key is stored in the file '$($outFilePath)'" -Foreground Cyan
    }

    if ($displayKey -or [string]::IsNullOrEmpty($outFilePath)) {
        Write-Host "Key: $base64Key" -Foreground Gray
    }
}

GenerateKey $passphrase $outFilePath $displayKey