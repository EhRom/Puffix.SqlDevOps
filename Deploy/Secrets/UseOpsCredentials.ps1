# Actions:
# 1. Process a JSON credentials file (encrypt new passwords)

param (
	[Parameter(Mandatory=$true,HelpMessage="Path to file which contains the credentials.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $credentialsPath,
		
	[Parameter(HelpMessage="Key (base 64 format) used to read and encrypt the credentials.")]
	[string] $key
)

# Collection of credentials
Class OpsCredentialsContainer {
    [bool] $isModified
	[System.Collections.Generic.Dictionary[string, OpsCredential]] $credentials

	OpsCredentialsContainer() {
		$this.credentials = New-Object "System.Collections.Generic.Dictionary[string, OpsCredential]"
        $this.isModified = $false
	}

    [void] AddCredential([OpsCredential] $credential) {
        if ($credential -eq $null) {
            # No Action
        }
        if ($this.credentials.ContainsKey($credential.name)) {
            $this.credentials[$credential.name] = $credential
        }
        else {
            $this.credentials.Add($credential.name, $credential)
        }
    }

    [OpsCredential] GetCredential([string] $credentialName) {
        [OpsCredential] $credential = $null

        if ($this.credentials.ContainsKey($credentialName)) {
            $credential = $this.credentials[$credentialName]
        }

        return $credential
    }
}

Class OpsCredential {
	[string] $name
	[string] $loginName
	[string] $encryptedPassword

	OpsCredential([string] $name, [string] $loginName) {
		$this.name = $name
		$this.loginName = $loginName
	}

    [void] SetPassword([string] $clearPassword, [string] $base64Key) {
        if([string]::IsNullOrEmpty($base64Key)) {
            $securePassword = ConvertTo-SecureString -String $clearPassword -AsPlainText -Force
            $this.encryptedPassword = ConvertFrom-SecureString -SecureString $securePassword
        } else {
            [byte[]] $key = [System.Convert]::FromBase64String($base64Key)
            $securePassword = ConvertTo-SecureString -String $clearPassword -AsPlainText -Force
            $this.encryptedPassword = ConvertFrom-SecureString -SecureString $securePassword -Key $key
        }
    }

    [void] SetEncryptedPassword([string] $encryptedPassword) {
        $this.encryptedPassword = $encryptedPassword
    }

    [SecureString] GetPassword([string] $base64Key) {
        [SecureString] $secureString = $null

        if([string]::IsNullOrEmpty($base64Key)) {
            $secureString = ConvertTo-SecureString -String $this.encryptedPassword
        } else {
            [byte[]] $key = [System.Convert]::FromBase64String($base64Key)
            $secureString = ConvertTo-SecureString -String $this.encryptedPassword -Key $key
        }

        return $secureString
    }
    
    [string] GetPasswordClear([string] $base64Key) {
        [SecureString] $secureString = $this.GetPassword($base64Key)

        $clearPassword = [System.Net.NetworkCredential]::new('', $secureString).Password
        return $clearPassword
    }
}

function LoadCredentials(
    [string] $credentialsPath,
    [string] $key
) {
    Write-Host "Load the credentials from the file '$($credentialsPath)'"

    $credentialsFileContent = Get-Content -Path $credentialsPath | Out-String
    $coreCredentialsContainer = ConvertFrom-Json $credentialsFileContent

    [OpsCredentialsContainer] $credentialsContainer = New-Object OpsCredentialsContainer
    
    # Retrieve credentials names (in the dictionary).
    $credentialNames = Get-Member -InputObject $coreCredentialsContainer.credentials -Membertype NoteProperty | Select-Object -Property Name

    foreach($credentialName in $credentialNames) {
        # Retrieve the credential properties
        $credentialProperties = Select-Object -InputObject $coreCredentialsContainer.credentials."$($credentialName.Name)" -Property name, loginName, encryptedPassword, newPassword

        if(-not [string]::Equals($credentialName.Name, $credentialProperties.name)) {
            Write-Host "The credential name ($($credentialProperties.name) mismatches the key name of the credential ($($credentialName.Name)). The credential is ignored)" -Foreground Yellow
        } else {
            Write-Host "Extract the information of the credential $($credentialProperties.name)" -Foreground Gray

            $currentCredential = New-Object OpsCredential($credentialProperties.name, $credentialProperties.loginName)

            if(-not [string]::IsNullOrEmpty($credentialProperties.newPassword)) {
                Write-Host "A new password is detected" -Foreground Magenta
                $currentCredential.SetPassword($credentialProperties.newPassword, $key)

                $credentialsContainer.isModified = $true
            } else {
                $currentCredential.SetEncryptedPassword($credentialProperties.encryptedPassword)
            }
            
            $credentialsContainer.AddCredential($currentCredential)
        }
    }

    return $credentialsContainer
}

function DisplayCredentials(
    [OpsCredentialsContainer] $credentialsContainer,
    [string] $key
) {
    Write-Host "$($credentialsContainer.credentials.Count) credentials to display." -Foreground Cyan

    if ($credentialsContainer.isModified) {
        Write-Host "The container contains new passwords"
    }

    foreach ($currentCredential in $credentialsContainer.credentials.Values) {
        Write-Host "$($currentCredential.name) > login: $($currentCredential.loginName)" -Foreground Gray
        
        # Display cleared passwords:
        # Uncomment this piece of code at your own risk > # Write-Host "Password:$($currentCredential.GetPasswordClear($key))" -Foreground Gray
    }
}

[OpsCredentialsContainer] $credentialsContainer = LoadCredentials $credentialsPath $key

# Uncomment this piece of code to dsplay the credentials stored in the file > # DisplayCredentials $credentialsContainer $key

# Export the credential container
$global:credentialsContainer = $credentialsContainer