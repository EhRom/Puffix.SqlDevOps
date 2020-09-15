# Create key

The **[CreateKey.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/CreateKey.ps1)** script file can be used to generate a basic encryption key. It can be stored in a file as a base 64 string.

## Usage

1. Generate a key and display it to the console
```powershell
.\CreateKey.ps1 -passphrase "sample passphrase, not so complex"
```

2. Generate a key, store it in a file and display it to the console
```powershell
.\CreateKey.ps1 -passphrase "sample passphrase, not so complex" -outFilePath keyfile.key
```

3. Generate a key, store it in a file and not display it to the console
```powershell
.\CreateKey.ps1 -passphrase "sample passphrase, not so complex" -outFilePath keyfile.key -displayKey $false
```