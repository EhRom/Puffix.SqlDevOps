# Manage credentials

These scripts are a way to use secured credentials and secrets without the need to store them in your source control.

## Sample credentials file
The **[BaseCredentialContainer.json](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/BaseCredentialContainer.json)** file is a sample which contains some sample credentials:
```json
{
    "credentials": {
        "credential1": {
            "name": "credential1",
            "loginName": "loginforcredential1",
            "newPassword": "Fill with the password for credential1"
        },
        "credential2": {
            "name": "credential2",
            "loginName": "loginforcredential2",
            "newPassword": "Fill with the password for credential2"
        }
    }
}
```

You can create use this sample file to add your own credentials.

## First level encryption script
Once done, the **[ManageOpsCredential.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/ManageOpsCredential.ps1)** is used to add a first level of encryption of the password. A key file is needed for this script (**[CreateKey.md](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/CreateKey.md)**).

The script is used with the following parameters:
* $credentialsPath: the path to target the JSON file you customized previously,
* $keyPath: the path to the file which contains the encryption key.

```powershell
$keyPath = "<Path to the key>"
$key =  Get-Content $keyPath
.\ManageOpsCredential.ps1 -credentialsPath .\CredentialContainer.json -key $key
```

The following file is then generated:
```json
{
    "credentials": {
        "credential1": {
            "name": "credential1",
            "loginName": "loginforcredential1",
            "encryptedPassword": "01000000..."
        },
        "credential2": {
            "name": "credential2",
            "loginName": "loginforcredential2",
            "encryptedPassword": "01000000..."
        },
        "credential3": {
            "name": "credential3",
            "loginName": "loginforcredential3",
            "encryptedPassword": "01000000..."
        }
    }
}
```

To change a password or add new credentials, replace the *encryptedPassword* field by a the *newPassword* field:
```json
{
    "credentials": {
        "credential1": {
            "name": "credential1",
            "loginName": "loginforcredential1",
            "encryptedPassword": "01000000..."
        },
        "credential2": {
            "name": "credential2",
            "loginName": "loginforcredential2",
            "encryptedPassword": "01000000..."
        },
        "credential3": {
            "name": "credential3",
            "loginName": "loginforcredential3",
            "newPassword": "New password for credential3"
        },
        "credentialB": {
            "name": "credentialB",
            "loginName": "loginforcredentialB",
            "newPassword": "New password for credentialB"
        }
    }
}
```

Execute the **[ManageOpsCredential.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/ManageOpsCredential.ps1)** script another time:
```powershell
$keyPath = "<Path to the key>"
$key =  Get-Content $keyPath
.\ManageOpsCredential.ps1 -credentialsPath .\CredentialContainer.json -key $key
```

The scripts generates the following content:
```json
{
    "credentials": {
        "credential1": {
            "name": "credential1",
            "loginName": "loginforcredential1",
            "encryptedPassword": "01000000..."
        },
        "credential2": {
            "name": "credential2",
            "loginName": "loginforcredential2",
            "encryptedPassword": "01000000..."
        },
        "credential3": {
            "name": "credential3",
            "loginName": "loginforcredential3",
            "encryptedPassword": "01000000..."
        },
        "credentialB": {
            "name": "credentialB",
            "loginName": "loginforcredentialB",
            "encryptedPassword": "01000000..."
        }
    }
}
```

## Credential container encryption
The **[EncryptOpsCredential.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/EncryptOpsCredential.ps1)** is used to encrypt the credential container (the JSON file based on the **[BaseCredentialContainer.json](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/BaseCredentialContainer.json)** model):
```powershell
$keyPath = "<Path to the key>"
$key =  Get-Content $keyPath
.\EncryptOpsCredential.ps1 -credentialsPath .\CredentialContainer.json -encryptedCredentialsPath .\CredentialContainer.enc -key $key
```

## Credential container decryption
The **[DecryptOpsCredential.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/DecryptOpsCredential.ps1)** is used to decrypt the encrypted credential container:
```powershell
$keyPath = "<Path to the key>"
$key =  Get-Content $keyPath
.\DecryptOpsCredential.ps1 -encryptedCredentialsPath .\CredentialContainer.enc -credentialsPath .\CredentialContainer.json -key $key
```

## Next
To use the credentials in your own scripts, the  **[UseOpsCredential.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/UseOpsCredential.ps1)** can be used (or integrated in your scripts).

Here is a sample to retrieve a credential:
```powershell
$keyPath = "<Path to the key>"
$key =  Get-Content $keyPath
.\UseOpsCredential.ps1 -credentialsPath .\CredentialContainer.json -key $key

$credentialName = "credentialB"
Write-Host "Find the '$credentialName' credential."
$opsCredential = $credentialContainer.GetCredential($credentialName)

if ($opsCredential -ne $null) {
    Write-Host "The '$credentialName' credential exists. Login:$($opsCredential.loginName)" -Foreground Green
} else {
    Write-Host "The '$credentialName' credential was not found." -Foreground Yellow
}

$pwshCredential = New-Object System.Management.Automation.PSCredential ($opsCredential.loginName, $opsCredential.GetPassword($key))

```