# Create key

The **[CreateKey.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/CreateKey.ps1)** script file can be used to generate a basic encryption key. It can be stored in a file as a base 64 string.

## Parameters

* ***passphrase*** (mandatory): a passphrase used to generate the key.
* ***outFilePath***: the path of the file to store the key.
* ***exportKey***: specifies whether the key is exported into a variable or not.
* ***displayKey***: specifies whether the key is displayed in the console or not. If the file path is not specified and the export is deactivated, the key will anyway be displayed.

## Usage

1. Generate a key and display it into the console
```powershell
.\CreateKey.ps1 -passphrase "sample passphrase, not so complex"
```

2. Generate a key, store it in a file and display it into the console
```powershell
.\CreateKey.ps1 -passphrase "sample passphrase, not so complex" -outFilePath keyfile.key
```

3. Generate a key, store it in a file and display it into the console
```powershell
.\CreateKey.ps1 -passphrase "sample passphrase, not so complex" -outFilePath keyfile.key -displayKey $true
```

4. Generate a key and export it into a variable
```powershell
.\CreateKey.ps1 -passphrase "sample passphrase, not so complex" -exportKey $true
Write-Host "Generated key > $($generatedKey)"
```

5. Generate a key, export it into a variable and display it into the console
```powershell
.\CreateKey.ps1 -passphrase "sample passphrase, not so complex" -exportKey $true -displayKey $true
Write-Host "Generated key > $($generatedKey)"
```

6. Generate a key, store it in a file and export it into a variable.
```powershell
.\CreateKey.ps1 -passphrase "sample passphrase, not so complex" -outFilePath keyfile.key -exportKey $true
Write-Host "Generated key > $($generatedKey)"
```

7. Generate a key, store it in a file, export it into a variable and display it into the console
```powershell
.\CreateKey.ps1 -passphrase "sample passphrase, not so complex" -outFilePath keyfile.key -exportKey $true -displayKey $true
Write-Host "Generated key > $($generatedKey)"
```

> [Next step > manage credentials in deployements](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/OpsCredentials.md)

> [Back to Deploy section](https://github.com/EhRom/Puffix.SqlDevOps/tree/master/Deploy)
> [Back to root](https://github.com/EhRom/Puffix.SqlDevOps)