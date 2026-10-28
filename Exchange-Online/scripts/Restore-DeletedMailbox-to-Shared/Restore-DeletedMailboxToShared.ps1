#Connect-ExchangeOnline 

  

$Softdeleted = Get-Mailbox -SoftDeletedMailbox  

  

foreach($User in $Softdeleted){ 

  

New-Mailbox  -Shared -Name $User.Name -DisplayName $User.Name -Alias $User.Name   

  

$ShareMailboxGetGUID = Get-Mailbox -Identity $user.Name 

  

$mailboxtoRestore = Get-Mailbox -Identity $User.Name -SoftDeletedMailbox | Select Name,PrimarySMTPAddress,DistinguishedName | Sort-Object Name  

  

New-MailboxRestoreRequest -SourceMailbox $mailboxtoRestore.DistinguishedName -TargetMailbox $ShareMailboxGetGUID.PrimarySmtpAddress -AllowLegacyDNMismatch 

  

$RestoreProgress = Get-MailboxRestoreRequest | Select Name,TargetMailbox,Status,RequestGuid | Out-GridView -Title Restore Request List -PassThru 

  

  

Get-MailboxRestoreRequestStatistics -Identity $RestoreProgress.RequestGuid | Select Name,StatusDetail,TargetAlias,PercentComplete 

  

  

} 