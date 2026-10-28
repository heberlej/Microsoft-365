$LiveCred = Get-Credential 

    $ExchangeServers = Get-ADGroup -Identity "Exchange Servers" | Get-ADGroupMember | Where-Object { $_.objectClass -eq 'computer' } 

    foreach ($Server in $ExchangeServers) { 

        $Data = Get-ADComputer -Identity $Server.SamAccountName -Properties Name, DNSHostName, OperatingSystem, DistinguishedName, ServicePrincipalName 

        [PSCustomObject] @{ 

            Name              = $Data.Name 

            FQDN              = $Data.DNSHostName 

            OperatingSystem   = $Data.OperatingSystem 

            DistinguishedName = $Data.DistinguishedName 

            Enabled           = $Data.Enabled 

        } 

    } 

$ExcServer = $Data.DNSHostName 

  

  

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$ExcServer/PowerShell/" -Credential $LiveCred -Authentication Kerberos 

Import-Pssession $Session 