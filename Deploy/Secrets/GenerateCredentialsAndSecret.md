# Generate credentials and secrets

This page contains a set of commands to deal with SecureString, secrets and key generation and management.

## Generate a secure string

Generate a **secure string** from a basic string:
```powershell
$plainText = "basic string to encrypt"
$secureString = ConvertTo-SecureString -String $plaintext -AsPlainText -Force
```

## Save the secure string to a file and load it from the file

Display the secure string in a powershell console, or save it into a variable:
```powershell
ConvertFrom-SecureString -SecureString $secureString
$secureStringContent = ConvertFrom-SecureString -SecureString $secureString
```

Save the secure string into a file:
```powershell
ConvertFrom-SecureString -SecureString $secureString | Out-File securestring.txt
```

Load the secure string from a file:
```powershell
$fileContent = Get-Content securestring.txt
$secureString = ConvertTo-SecureString -String $fileContent
```

## Display the secure string content

Display the secure string content *(the following command is only available in PowerShell Core)*:
```powershell
ConvertFrom-SecureString -SecureString $secureString -AsPlainText
```

Display the secure string content (method 1):
```powershell
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
$clearText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
Write-Host $clearText
```

Display the secure string content (method 2):
```powershell
$clearText = [System.Net.NetworkCredential]::new('', $secureString).Password
Write-Host $clearText
```

## Generate a key

To use more secured string, keys can be used.

Generate the key from a passphrase and get a base 64 string:
```powershell
$encoding = [System.Text.Encoding]::Unicode
$sha256 = New-Object System.Security.Cryptography.SHA256CryptoServiceProvider 

$baseKeyText = "Texte pas très aléatoire pour générer un Hash pour sécuriser des contenus."
$keyTextBytes = $encoding.GetBytes($baseKeyText) 

$key = $sha256.ComputeHash($keyTextBytes)
Write-Host $key

$base64Key = [System.Convert]::ToBase64String($key)
```

Get the bytes from the secure string, to retrive the key:
```powershell
$key = [System.Convert]::FromBase64String($base64Key)
Write-Host $key
```

The base 64 string can then stored to a file.

Note: the script [CreateKey.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/CreateKey.ps1) (documentation: *[CreateKey.md](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/CreateKey.md)*) can be used to generate a key.

## Save the secure string to a file and load it from the file with a key

Display the secure string in a powershell console, or save it into a variable:
```powershell
ConvertFrom-SecureString -SecureString $secureString -Key $key
$secureStringContent = ConvertFrom-SecureString -SecureString $secureString -Key $key
```

Save the secure string into a file:
```powershell
ConvertFrom-SecureString -SecureString $secureString -Key $key | Out-File securestringwithkey.txt
```

Load the secure string from a file:
```powershell
$fileContent = Get-Content securestringwithkey.txt
$secureString = ConvertTo-SecureString -String $fileContent -Key $key
```

[Next step > manage key](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/CreateKey.md)


[Back to Deploy section](https://github.com/EhRom/Puffix.SqlDevOps/tree/master/Deploy)

[Back to root](https://github.com/EhRom/Puffix.SqlDevOps)