# Activate WinRM

The scripts used to deploy the SSIS pacakges and environments and the SQL Agent jobs require to be executed on the target machine. Indeed, the scrips requires librairies which are not always available on Azure Dev Ops deployement agent but are required on the target machine (which embed SQL Server).

To activate WinRM, you need to execute on each target machine (which runs SQL Server) the following commmands (in a PowerShell console, **as administrator**).

WinRM requires PowerShell version 4.0 and above. To control the version, use the following command:
```
$PSVersionTable.PSVersion
```

Activate the following firewall rules:
```
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
```
> You may have to translate the rule group name in the OS language. For example, in french, you should use "Partage de fichiers et d'imprimantes".

On each server, copy the [ConfigureWinRM.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/WinRM/ConfigureWinRM.ps1) script, and run the command:
```
ConfigureWinRM.ps1 <fullyqualifiedservernane.mydomain.local> https
```

If the machine is also part of an high availibility group (Always ON), run also the command:
```
ConfigureWinRM.ps1 <sqlalwaysonlistener.mydomain.local> https
```


More information available on [Microsoft Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/apps/cd/deploy-webdeploy-iis-winrm?view=azure-devops#winrm-configuration).

> [Back to root](https://github.com/EhRom/Puffix.SqlDevOps/tree/master/Deploy)