Get-ADUser -Properties *  -Filter * >> c:\temp\backup-ad.txt 

Get-ADUser -Properties *  -Filter {ProxyAddresses -like '*@contoso.com' -AND ProxyAddresses -notlike '*Health*' -AND ProxyAddresses -notlike '*SystemM*' -AND ProxyAddresses -notlike '*Migration*' -AND ProxyAddresses -notlike '*FederatedE*' -AND ProxyAddresses -notlike '*MsExchD*'} |  

  

ForEach { # Account may have more than one email address in scope so need to loop through each one 

ForEach ($proxyAddress in $_.proxyAddresses) { 

If ($proxyAddress -like '*@contoso.com') { 

Write-Host $proxyAddress 

Set-ADUser $_.SamAccountName -Remove @{ProxyAddresses=$proxyAddress} 

} 

} 

} 

  

  

  

Get-ADUser -Properties *  -Filter * >> c:\temp\backup-ad-danach.txt 