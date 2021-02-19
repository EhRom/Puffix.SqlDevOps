# Azure Point-To-Site VPN setup and configuration

An **Azure Point-to-Site (P2S)** VPN is a link between your local computer and a **Network Gateway** in Azure. The gateway is linked to a private network (**Virtual Network**) in Azure.

## Links
To deploy an **Azure Point-to-Site (P2S)** VPN you will find the documentation following these links:
- Main documentation: [vpn-gateway : howto point-to-site resource manager portal | docs.microsot.com](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-resource-manager-portal) 
- Create self-signed certificate with Power Shell: [vpn-gateway : certificates point-to-site > clientcert | docs.microsot.com](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site#clientcert)

You will find in this repository some basic scripts to manage your self-signed certificates on Windows machine.

*More to come soon*

### Generate root certifcate
```powershell
.\CreateRootSelfSignedCertificate.ps1 -baseName "<base certificate name>" -rootCertificateFilePath .\<root certificate file name>.cer -export $true(default)|$false
```

Sample:
```powershell
$baseName = "MyOrganizationName"
$rootCertificateFileName = "AzureP2S$($baseName)Root.cer"

.\CreateRootSelfSignedCertificate.ps1 -baseName $baseName -rootCertificateFilePath .\$rootCertificateFileName
```

### Generate child certifcate
```powershell
.\CreateChildCertificate.ps1 -baseName "<base certificate name>" -childName "<child certificate name>" -rootCertificateSerialNumber "<root certificate serial number>" -childCertificateFilePath .\<child certificate file name>.cer -export $true(default)|$false
```

Sample (assume the previous sample is executed):
```powershell
$childCertificateName = "Me"
$childCertificateFileName = "AzureP2S$($baseName)_$($childCertificateName).cer"

.\CreateChildCertificate.ps1 -baseName $baseName -childName $childCertificateName -rootCertificateThumbprint $rootCertificateThumbprint -childCertificateFilePath .\$childCertificateFileName
```

*More to come soon (import certificate in root certification authorities | export pfx | delete certificate | base 64 conversion)*

[Back to Deploy section](https://github.com/EhRom/Puffix.SqlDevOps/tree/master/Deploy)

[Back to root](https://github.com/EhRom/Puffix.SqlDevOps)