
(Get-ADDomainController -Filter *).Name |Foreach-Object { repadmin /syncall $_ (Get-ADDomain).DistinguishedName /Ade }
