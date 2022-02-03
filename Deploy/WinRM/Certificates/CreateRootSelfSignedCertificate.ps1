param (
	[Parameter(Mandatory=$true,HelpMessage="Name of the root certificate")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $rootCertificateName,

	[Parameter(HelpMessage="Target directory where to export the generated certificates. If not set, the certificate is not saved to a file.")]
    [string] $targetDirectoryPath,

	[Parameter(HelpMessage="Specify whether the certificate name, thumbprint and serial number are exported or not.")]
	[bool] $export = $true
)

$rootCertificateSubject = "CN=$($rootCertificateName)"

Write-Host "Generate the root certificate $($rootCertificateName)"

Try {
    $certificateLocation = "Cert:\CurrentUser\My"
    $rootCertificate = New-SelfSignedCertificate -Type Custom -DnsName $rootCertificateName -KeySpec Signature `
            -Subject $rootCertificateSubject -KeyExportPolicy Exportable `
            -HashAlgorithm sha256 -KeyLength 4096 `
            -CertStoreLocation $certificateLocation -KeyUsageProperty Sign -KeyUsage CertSign

    Write-Host "The root certificate $($rootCertificateName) is generated" -ForegroundColor Green
}
Catch {
    $errorMessage = $_.Exception.Message
    $failedItem = $_.Exception.ItemName
    Write-Error "Error while creating the certificate $rootCertificateName -> $failedItem : $errorMessage"
}

# Export the certificate
if ($export) {
    $rootCertificateSerialNumber = $rootCertificate.GetSerialNumberString()
    $rootCertificateThumbprint = $rootCertificate.Thumbprint

    Write-Host "The root certificate $($rootCertificateName) serial number is $rootCertificateSerialNumber, and its thumbprint is $rootCertificateThumbprint" -ForegroundColor Cyan
    Write-Host "The root certificate name is available in the `$rootCertificateName variable, the serial number, in the `$rootCertificateSerialNumber variable, and the thumbprint, in the `$rootCertificateThumbprint variable." -ForegroundColor Gray
    $global:rootCertificateName = $rootCertificateName
    $global:rootCertificateSerialNumber = $rootCertificateSerialNumber
    $global:rootCertificateThumbprint = $rootCertificateThumbprint
}

if(-not([string]::IsNullOrEmpty($targetDirectoryPath))) {
    $rootCertificateFilePath = [System.IO.Path]::Combine($targetDirectoryPath, "$($rootCertificateName).cer")
    $certificateContent = @(
        '-----BEGIN CERTIFICATE-----'
        [System.Convert]::ToBase64String($rootCertificate.RawData, 'InsertLineBreaks')
        '-----END CERTIFICATE-----'
    )

    $certificateContent  | Out-File -FilePath $rootCertificateFilePath -Encoding utf8
    Write-Host "The root certificate is stored in the following file: $($rootCertificateFilePath)." -ForegroundColor Green
}