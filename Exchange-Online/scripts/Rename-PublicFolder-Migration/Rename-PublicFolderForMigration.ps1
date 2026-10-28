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

  

#####################################################################################  

[CmdletBinding()] 

Param( 

  [string] $PublicFolderServer = $ExcServer 

) 

  

Write-Host ('Fetching Public Folder Statistic on Server {0}' -f ($PublicFolderServer)) 

  

# Fetch Public Folders containing unsupported characters 

$FilteredFolders = Get-PublicFolderStatistics -ResultSize Unlimited  | Where-Object {($_.Name -like "*\*")-or ($_.Name -like "*/*") }  

  

Write-Host ('Found {0} public folders' -f ($FilteredFolders | Measure-Object).Count) 

  

foreach($Folder in $FilteredFolders) { 

  $Name = $Folder.Name.Replace('\','|').Replace('/','|') 

  Write-Host ('Fixing folder: [{0}] > [{1}]' -f $Folder.Name, ($Name)) 

  Set-PublicFolder -Identity $Folder.EntryId -Name $Name 

} 