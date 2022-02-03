# Create certificates

The following scripts are used to generate a self-signed root certificate and children certifciates

### Generate root certifcate
```powershell
.\CreateRootSelfSignedCertificate.ps1 -rootCertificateName "<root certificate name>" -targetDirectoryPath .\<target directory path> -export $true(default)|$false
```

If the parameer *export* is set to true, the following variables are exported:
- `$rootCertificateName`: contains the name of the generated certificate,
- `$rootCertificateSerialNumber`: contains the serial number of the generated certificate,
- `$rootCertificateThumbprint`: contains the thumbprint of the generated certificate.

Sample:
```powershell
$rootCertificateName = "MyOrganizationName"
$targetDirectoryPath = "C:\Certificates\"

.\CreateRootSelfSignedCertificate.ps1 -rootCertificateName $rootCertificateName -targetDirectoryPath $targetDirectoryPath
```

### Generate child certifcate
```powershell
.\CreateChildCertificate.ps1 -childCertificateName "<child certificate name>" -rootCertificateThumbprint "<root certificate thumbrpint>" -targetDirectoryPath .\<target directory path> -export $true(default)|$false
```

If the parameer *export* is set to true, the following variables are exported:
- `$childCertificateName`: contains the name of the generated certificate,
- `$childCertificateSerialNumber`: contains the serial number of the generated certificate,
- `$childCertificateThumbprint`: contains the thumbprint of the generated certificate.

Sample (assume the previous sample is executed):
```powershell
$childCertificateName = "MeFrom$(rootCertificateName)"

.\CreateChildCertificate.ps1 -childCertificateName $childCertificateName -rootCertificateThumbprint $rootCertificateThumbprint -targetDirectoryPath $targetDirectoryPath
```

[Back to Deploy section](https://github.com/EhRom/Puffix.SqlDevOps/tree/master/Deploy)

[Back to root](https://github.com/EhRom/Puffix.SqlDevOps)