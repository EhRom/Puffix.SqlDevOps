Write-Host "Generate and register self-signed certificate for the computer '$($env:computerName)'" -ForegroundColor Cyan


$cert = New-SelfSignedCertificate -DnsName $env:computerName -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 -KeyLength 4096 -CertStoreLocation "cert:\LocalMachine\My"

Write-Host "Certificate generated: Thumbprint: $($cert.Thumbprint)." -ForegroundColor Green

Export-Certificate -Cert $cert -FilePath ".\$($cert.Thumbprint).cer"
Import-Certificate -FilePath ".\$($cert.Thumbprint).cer" -CertStoreLocation "cert:\LocalMachine\Root"


Write-Host "Certificate has been added to the Root Certification Authority." -ForegroundColor Green

Remove-Item ".\$($cert.Thumbprint).cer"

Write-Host "Register the certificate for use for PS Remote Sessions"

Get-ChildItem wsman:\localhost\Listener

Get-ChildItem wsman:\localhost\Listener\ | Where-Object -Property Keys -eq 'Transport=HTTPS' | Remove-Item -Recurse
New-Item -Path WSMan:\localhost\Listener\ -Transport HTTPS -Address * -CertificateThumbPrint $cert.Thumbprint -Force

Get-ChildItem wsman:\localhost\Listener
Restart-Service WinRM

Write-Host "The new certificate is registered for use for PS Remote Sessions" -ForegroundColor Green

# Test
# Enter-PSSession -ComputerName $env:computerName -UseSSL