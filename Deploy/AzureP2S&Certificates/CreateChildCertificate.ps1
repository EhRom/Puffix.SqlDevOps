# Actions:
# 1. Process a JSON credentials file (encrypt new passwords)

param (
	[Parameter(Mandatory=$true,HelpMessage="Base name of the certificate")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $baseName,
    
	[Parameter(Mandatory=$true,HelpMessage="Name of the child certificate")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $childName,

	[Parameter(Mandatory=$true,HelpMessage="Thumbprint of the root certificate")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $rootCertificateThumbprint,

	[Parameter(HelpMessage="Certificate file path for export. If not set, the certificate is not saved as a file.")]
    [string] $childCertificateFilePath,

	[Parameter(HelpMessage="Specify whether the certificate name, thumbprint and serial number are exported or not.")]
	[bool] $export = $true
)

$childCertificateDnsName = "AzureP2S$($baseName)_$($childName)"
$childCertificateName = "CN=$($childCertificateDnsName)"

Write-Host "Generate the child certificate $($childCertificateName)"

Try {
    $certificateLocation = "Cert:\CurrentUser\My"
    $rootCertificatePath = "$($certificateLocation)\$($rootCertificateThumbprint)"

    $rootCertificate = Get-ChildItem -Path $rootCertificatePath

    $childCertificate =  New-SelfSignedCertificate -Type Custom -DnsName $childCertificateDnsName -KeySpec Signature `
        -Subject $childCertificateName -KeyExportPolicy Exportable `
        -HashAlgorithm sha256 -KeyLength 4096 `
        -CertStoreLocation $certificateLocation `
        -Signer $rootCertificate `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
        
    $childCertificateSerialNumber = $childCertificate.GetSerialNumberString()

    Write-Host "The child certificate $($childCertificateName) is generated" -ForegroundColor Green
}
Catch {
    $errorMessage = $_.Exception.Message
    $failedItem = $_.Exception.ItemName
    Write-Error "Error while creating the certificate $childCertificateName -> $failedItem : $errorMessage"
}

# Export the credential container
if ($exportSerialNumber) {
    $childCertificateSerialNumber = $childCertificate.GetSerialNumberString()
    $childCertificateThumbprint = $childCertificate.Thumbprint()

    Write-Host "The child certificate $($childCertificateName) serial number is $childCertificateSerialNumber, and its thumbprint is $childCertificateThumbprint" -ForegroundColor Cyan
    Write-Host "The child certificate name is available in the `$childCertificateName variable, the serial number, in the `$childCertificateSerialNumber variable, and the thumbprint, in the `$childCertificateThumbprint variable." -ForegroundColor Gray
    $global:childCertificateName = $childCertificateName
    $global:childCertificateSerialNumber = $childCertificateSerialNumber
    $global:childCertificateThumbprint = $childCertificateThumbprint
}

if(-not([string]::IsNullOrEmpty($childCertificateFilePath))) {

    $certificateContent = @(
        '-----BEGIN CERTIFICATE-----'
        [System.Convert]::ToBase64String($childCertificate.RawData, 'InsertLineBreaks')
        '-----END CERTIFICATE-----'
    )

    $certificateContent  | Out-File -FilePath $childCertificateFilePath -Encoding utf8
    Write-Host "The root certificate is stored in the following file: $($childCertificateFilePath)." -ForegroundColor Green
}