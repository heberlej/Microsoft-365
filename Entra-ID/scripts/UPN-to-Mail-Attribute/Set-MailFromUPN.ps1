# SearchBase an die eigene OU anpassen
$SearchBase = "OU=Benutzer,DC=contoso,DC=com"

# UPN -> mail
Get-ADUser -SearchBase $SearchBase -LDAPFilter '(userPrincipalName=*)' -Properties userPrincipalName, mail |
    ForEach-Object { Set-ADObject -Identity $_.DistinguishedName -Replace @{ mail = $_.userPrincipalName } }

# Andersrum: mail -> UPN
# Get-ADUser -SearchBase $SearchBase -LDAPFilter '(mail=*)' -Properties userPrincipalName, mail |
#     ForEach-Object { Set-ADObject -Identity $_.DistinguishedName -Replace @{ userPrincipalName = $_.mail } }
