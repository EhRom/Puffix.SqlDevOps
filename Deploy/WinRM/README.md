# Activate WinRM

The scripts used to deploy the SSIS packages and environments and the SQL Agent jobs require to be executed on the target machine. Indeed, the scrips requires librairies which are not always available on Azure Dev Ops deployement agent but are required on the target machine (which embed SQL Server).

To activate WinRM, you need to execute on each target machine (which runs SQL Server) the following commmands (in a PowerShell console, **as administrator**).

## Check PowerShell verion

WinRM requires PowerShell version 4.0 and above. To control the version, use the following command:
```
$PSVersionTable.PSVersion
```

## Activate Firewall rules

Activate the following firewall rules **on the target machine**:

```powershell
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
```

> You may have to translate the rule group name in the OS language. For example, in french, you should use "Partage de fichiers et d'imprimantes".

You may need to list the rules by your own:

```powershell
netsh advfirewall monitor show firewall rule name=all
```

Or activate the rules manually in the firewall advanced view.

## Activate WinRM

On each server, copy the [ConfigureWinRM.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/WinRM/ConfigureWinRM.ps1) script (source: [Microsoft Github repo](https://github.com/microsoft/azure-pipelines-extensions/blob/master/TaskModules/powershell/WinRM/WinRM-Http-Https/ConfigureWinRM.ps1), and run the command **on the target machine**:

```powershell
.\ConfigureWinRM.ps1 <fullyqualifiedservernane.mydomain.local> https
```

If the machine is also part of an high availibility group (Always ON), run also the command:

```powershell
.\ConfigureWinRM.ps1 <sqlalwaysonlistener.mydomain.local> https
```

> The WinRM certificates expires each year. To renew the certificate, the `ConfigureWinRM.ps1` can be executed with the same parameters **on the target machine**.

## Test WinRM

Test if the connection works from the **source machine**. Add `-UseSSL` to force *https* connection, and `-SkipCACheck` if the certificate is self-signed:

```powershell
Enter-PSSession <fullyqualifiedservernane.mydomain.local> -UseSSL

Enter-PSSession <sqlalwaysonlistener.mydomain.local> -UseSSL
```

If the certificate is self-signed, the parameters `-SkipCACheck` can be added, and the `-SkipCNCheck` eventually, if the certificate does not match the machine name:

```powershell
$psSessionOption = New-PSSessionOption -SkipCACheck [-SkipCNCheck]

Enter-PSSession <fullyqualifiedservernane.mydomain.local> -UseSSL -SessionOption $psSessionOption

Enter-PSSession <sqlalwaysonlistener.mydomain.local> -UseSSL -SessionOption $psSessionOption
```

To quit the *PS-Session* enter the `exit` command

```powershell
exit
```

## Check user rights

If the user used for WinRM is not in the admimstrator group **on the target machine**, you should add this user to the **Remote Management Users** group ("Utilisateur de gestion à distance" on french machines).

## Allow the source machine

Additionnaly, you can test if the WinRM source machine is allowed to connect to the target machine with the command below:

```powershell
winrm get winrm/config/client
```

To allow the source machine, enter the following command (on a Powershell Command Promt on the target machine):

```powershell
Set-Item WSMan:\localhost\Client\TrustedHosts <fullyqualifiedsourcemachine.mydomain.local>
```

## See also

More information available on [Microsoft Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/apps/cd/deploy-webdeploy-iis-winrm).

[Back to Deploy section](https://github.com/EhRom/Puffix.SqlDevOps/tree/master/Deploy)

[Back to root](https://github.com/EhRom/Puffix.SqlDevOps)
