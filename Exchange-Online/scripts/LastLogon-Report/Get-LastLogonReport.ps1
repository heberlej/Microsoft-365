<#  

  

Das Skript ist dafür da den letzten Login der User herauszufinden   

  

   

  

 

  

   

  

V.1 Jan Heberle  

  

   

  

   

  

#>  

  

   

  

   

  

Param  

  

(  

  

    [Parameter(Mandatory = $false)]  

  

    [int]$InactiveDays,  

  

    [switch]$UserMailboxOnly,  

  

    [switch]$ReturnNeverLoggedInMB,  

  

    [string]$UserName,  

  

    [string]$Password,  

  

    [switch]$MFA  

  

   

  

)  

  

measure-command{  

  

#Connect-ExchangeOnline  

  

#Connect-MsolService  

  

   

  

   

  

$ExportCSV=".\LastLogonTimeReport_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv"  

  

   

  

   

  

   

  

   

  

$Result=""  

  

$Output=@()  

  

$MBUserCount=0  

  

$OutputCount=0  

  

   

  

   

  

Get-Mailbox -ResultSize Unlimited | Where{$_.DisplayName -notlike "Discovery Search Mailbox"} | ForEach-Object{  

  

$upn=$_.UserPrincipalName  

  

$CreationTime=$_.WhenMailboxCreated  

  

$LastLogonTime=(Get-MailboxStatistics -Identity $upn).lastlogontime  

  

$DisplayName=$_.DisplayName  

  

$Print=1  

  

$MBUserCount++  

  

$RolesAssigned=""  

  

Write-Progress -Activity "`n     Processed mailbox count: $MBUserCount "`n"  Currently Processing: $DisplayName"  

  

   

  

if($LastLogonTime -eq $null)  

  

{  

  

   $LastLogonTime ="Garnicht"  

  

   $InactiveDaysOfUser="-"  

  

}  

  

else  

  

{  

  

   $InactiveDaysOfUser= (New-TimeSpan -Start $LastLogonTime).Days  

  

}  

  

   

  

if(($ReturnNeverLoggedInMB.IsPresent) -and ($LastLogonTime -ne "Never logged in"))  

  

{  

  

  $Print=0  

  

}  

  

   

  

if($Print -eq 1)  

  

{  

  

  $OutputCount++  

  

  $Result=@{'UserPrincipalName'=$upn;'DisplayName'=$DisplayName;'LastLogonTime'=$LastLogonTime;'CreationTime'=$CreationTime;'InactiveDays'=$InactiveDaysOfUser;'MailboxType'=$MBType; 'AssignedLicenses'=$AssignedLicense;'Roles'=$RolesAssigned}  

  

  $Output= New-Object PSObject -Property $Result  

  

  $Output | Select-Object UserPrincipalName,DisplayName,LastLogonTime,CreationTime,InactiveDays | Export-Csv -Path $ExportCSV -Notype -Append  

  

}  

  

}  

  

   

  

Write-Host `nScript executed successfully  

  

if((Test-Path -Path $ExportCSV) -eq "True")  

  

{  

  

   

  

Write-Host "Detailed report available in: $ExportCSV"  

  

$Prompt = New-Object -ComObject wscript.shell  

  

$UserInput = $Prompt.popup("Do you want to open output file?",`  

  

0,"Open Output File",4)  

  

If ($UserInput -eq 6)  

  

{  

  

  Invoke-Item "$ExportCSV"  

  

}  

  

}  

  

Else  

  

{  

  

  Write-Host No mailbox found  

  

}  

  

Get-PSSession | Remove-PSSession  

  

}  