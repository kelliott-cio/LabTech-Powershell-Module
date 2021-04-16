# Specify the RDS licensing type: 2 - Per Device CAL, 4 - Per User CAL
$RDSCALMode = 4
# RDS Licensing host name
$RDSlicServer = "127.0.0.1"
# Set the server name and type of licensing in the registry
New-Item "HKLM:\SYSTEM\CurrentControlSet\Services\TermService\Parameters\LicenseServers"
New-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\TermService\Parameters\LicenseServers" -Name SpecifiedLicenseServers -Value $RDSlicServer -PropertyType "MultiString"
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\Licensing Core\" -Name "LicensingMode" -Value $RDSCALMode