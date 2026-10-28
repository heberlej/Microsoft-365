CLS 

Write-Host "Finding Azure Active Directory Accounts..." 

  

#$Group = Get-Msolgroup -SearchString <MFA-GRUPPE> 

#$Users= Get-Msolgroupmember -GroupObjectId $Group.ObjectId -All | ? {$_.IsLicensed -eq $True} 

  

$Users = Get-MsolUser -All | ? {$_.IsLicensed -eq $True} 

$Report = [System.Collections.Generic.List[Object]]::new() # Create output file 

Write-Host "Processing" $Users.Count "accounts..."  

ForEach ($User in $Users) { 

   $MFAMethods = $User.StrongAuthenticationMethods.MethodType 

   $MFAEnforced = $User.StrongAuthenticationRequirements.State 

   $DefaultMFAMethod = ($User.StrongAuthenticationMethods | ? {$_.IsDefault -eq "True"}).MethodType 

   If (($MFAEnforced -eq "Enforced") -or ($MFAEnforced -eq "Enabled")) { 

      Switch ($DefaultMFAMethod) { 

        "OneWaySMS"             { $MethodUsed = "One-way SMS" } 

        "TwoWayVoiceMobile"     { $MethodUsed = "Phone call verification" } 

        "PhoneAppOTP"           { $MethodUsed = "Hardware token or authenticator app" } 

        "PhoneAppNotification"  { $MethodUsed = "Authenticator app" } 

      } #End Switch 

    } 

    Else { 

          $MFAEnforced= "Not Enabled" 

          $MethodUsed = "MFA Not Used" } 

   

   $ReportLine = [PSCustomObject] @{ 

           User        = $User.UserPrincipalName 

           Name        = $User.DisplayName 

           MFAUsed     = $MFAEnforced 

           MFAMethod   = $MethodUsed } 

                  

    $Report.Add($ReportLine)  

} # End For 

  

Write-Host "Report is in c:\temp\MFAUsers.CSV" 

$Report | Select Name, MFAMethod | Out-GridView 

$Report | Export-CSV -NoTypeInformation c:\temp\MFAUsers.CSV 

Variante: nur lizenzierte Mitglieder einer Gruppe  

 ############################################################################################################

CLS 

Write-Host "Finding Azure Active Directory Accounts..." 

  

$Group = Get-Msolgroup -SearchString <MFA-GRUPPE> 

$Userst= Get-Msolgroupmember -GroupObjectId $Group.ObjectId -All | ? {$_.IsLicensed -eq $True}  

  

  

  

#$Users = Get-MsolUser -All | ? {$_.IsLicensed -eq $True} 

$Report = [System.Collections.Generic.List[Object]]::new() # Create output file 

Write-Host "Processing" $Users.Count "accounts..."  

ForEach ($Users in $Userst) { 

$user = Get-MsolUser -ObjectId $Users.ObjectId 

     

   $MFAMethods = $User.StrongAuthenticationMethods.MethodType 

   $MFAEnforced = $User.StrongAuthenticationRequirements.State 

   $DefaultMFAMethod = ($User.StrongAuthenticationMethods | ? {$_.IsDefault -eq "True"}).MethodType 

   If (($MFAEnforced -eq "Enforced") -or ($MFAEnforced -eq "Enabled")) { 

      Switch ($DefaultMFAMethod) { 

        "OneWaySMS"             { $MethodUsed = "One-way SMS" } 

        "TwoWayVoiceMobile"     { $MethodUsed = "Phone call verification" } 

        "PhoneAppOTP"           { $MethodUsed = "Hardware token or authenticator app" } 

        "PhoneAppNotification"  { $MethodUsed = "Authenticator app" } 

      } #End Switch 

    } 

    Else { 

          $MFAEnforced= "Not Enabled" 

          $MethodUsed = "MFA Not Used" } 

   

   $ReportLine = [PSCustomObject] @{ 

           User        = $User.UserPrincipalName 

           Name        = $User.DisplayName 

           MFAUsed     = $MFAEnforced 

           MFAMethod   = $MethodUsed } 

                  

    $Report.Add($ReportLine)  

} # End For 

  

Write-Host "Report is in c:\temp\MFAUsers.CSV" 

$Report | Select Name, MFAUsed, MFAMethod | Out-GridView 

$Report | Export-CSV -NoTypeInformation c:\temp\MFAUsers.CSV 