# Actions : generate a key from a passphrase.
param (
	[Parameter(Mandatory=$true,HelpMessage="Passphrase used to generate the key. It must be secured and secret.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $passphrase,
		
	[Parameter(HelpMessage="Path of the file to store the key. If not specified, the key is only displayed.")]
	[string] $outFilePath,

    [Parameter(HelpMessage="Specifies whether the key is exported into a variable or not.")]
	[bool] $exportKey = $false,

    [Parameter(HelpMessage="Specifies whether the key is displayed into the console or not. If the file path is not specified or the export is deactivated, the key will anyway be displayed.")]
	[bool] $displayKey = $false
)

function GenerateKey (
    [string] $passphrase,
    [string] $outFilePath,
    [bool] $exportKey,
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

    if ($exportKey) {
        $global:generatedKey = $generatedKey
        Write-Host "The key is available in the `$generatedKey variable" -Foreground Gray
    }

    if ($displayKey -or ([string]::IsNullOrEmpty($outFilePath) -and -not $exportKey)) {
        Write-Host "Key: $base64Key" -Foreground Gray
    }
}

GenerateKey -passphrase $passphrase -outFilePath $outFilePath -exportKey $exportKey -displayKey $displayKey
