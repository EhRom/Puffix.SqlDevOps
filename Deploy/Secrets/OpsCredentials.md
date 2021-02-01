# Manage credentials

These scripts are a way to use secured credentials and secrets without the need to store them in your source control.

## Sample credentials file
The **[BaseCredentialsContainer.json](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/BaseCredentialsContainer.json)** file is a sample which contains some sample credentials:
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
Once done, the **[ManageOpsCredentials.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/ManageOpsCredentials.ps1)** is used to add a first level of encryption of the password. A key is needed for this script (**[CreateKey.md](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/CreateKey.md)**).

The script is used with the following parameters:
* ***credentialsPath***: the path to target the JSON file you customized previously,
* ***key***: the encryption key in the base64 format.

The sample bellow generate a key stored in a file. The file content is read and stored in the *$key* variable:

```powershell
$keyPath = "<Path to the key>"
$key =  Get-Content $keyPath
.\ManageOpsCredentials.ps1 -credentialsPath .\CredentialsContainer.json -key $key
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

Execute the **[ManageOpsCredentials.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/ManageOpsCredentials.ps1)** script another time:
```powershell
$keyPath = "<Path to the key>"
$key =  Get-Content $keyPath
.\ManageOpsCredentials.ps1 -credentialsPath .\CredentialsContainer.json -key $key
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
The **[EncryptOpsCredentials.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/EncryptOpsCredentials.ps1)** is used to encrypt the credential container (the JSON file based on the **[BaseCredentialsContainer.json](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/BaseCredentialsContainer.json)** model).

The script takes three parameters:
* ***credentialsPath***: the path to target the JSON file which contains the credentials,
* ***encryptedCredentialsPath***: the path to target the file which will contain the encrypted credentials,
* ***key***: the encryption key in the base64 format.

```powershell
$keyPath = "<Path to the key>"
$key =  Get-Content $keyPath
.\EncryptOpsCredentials.ps1 -credentialsPath .\CredentialsContainer.json -encryptedCredentialsPath .\CredentialsContainer.enc -key $key
```

## Credential container decryption
The **[DecryptOpsCredentials.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/DecryptOpsCredentials.ps1)** is used to decrypt the encrypted credential container.

The script takes three parameters:
* ***encryptedCredentialsPath***: the path to target the file which contains the encrypted credentials,
* ***credentialsPath***: the path to target the JSON file which will contain the decrypted credentials,
* ***key***: the encryption key in the base64 format.

```powershell
$keyPath = "<Path to the key>"
$key =  Get-Content $keyPath
.\DecryptOpsCredentials.ps1 -encryptedCredentialsPath .\CredentialsContainer.enc -credentialsPath .\CredentialsContainer.json -key $key
```

## Next
To use the credentials in your own scripts, the  **[UseOpsCredentials.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/Secrets/UseOpsCredentials.ps1)** can be used (or integrated in your scripts).

The script takes two parameters:
* ***credentialsPath***: the path to target the JSON file which contains the credentials,
* ***key***: the encryption key in the base64 format.

The credentials are loaded into the variable ***$credentialsContainer***.

Here is a sample to retrieve a credential:
```powershell
$keyPath = "<Path to the key>"
$key =  Get-Content $keyPath
.\UseOpsCredentials.ps1 -credentialsPath .\CredentialsContainer.json -key $key

$credentialName = "credentialB"
Write-Host "Find the '$credentialName' credential."
$opsCredential = $credentialsContainer.GetCredential($credentialName)

if ($opsCredential -ne $null) {
    Write-Host "The '$credentialName' credential exists. Login:$($opsCredential.loginName)" -Foreground Green
} else {
    Write-Host "The '$credentialName' credential was not found." -Foreground Yellow
}

$pwshCredential = New-Object System.Management.Automation.PSCredential ($opsCredential.loginName, $opsCredential.GetPassword($key))
```

> [Back to root](https://github.com/EhRom/Puffix.SqlDevOps/tree/master/Deploy)