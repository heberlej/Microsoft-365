<# 

Author: Jan Heberle | Firma Netplans  

  

Das Skript ist für die Bereitstellung von SharePoint Seiten über eine GPO, erstellt wird hier ein fertiger String, welchen man 

in die GPO eintragen kann.  

  

#> 

  

  

  

$AdminUrl = "https://contoso-admin.sharepoint.com/" 

$Credentials = Get-Credential 

Connect-SPOService -Url $AdminUrl -Credential $Credentials 

$Websites = Get-SPOSite -Limit ALL 

$TenantID=Get-PnPTenantID 

 $Cred= Get-Credential 

foreach($Website in $Websites){ 

  

#Parameter 

$SiteURL=$Website.URL 

$ListName = "Dokumente" 

$Title = $Website.Title 

  

 

  

  

#Setup the context 

$Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL) 

$Ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password) 

  

#Get Site and Web Objects 

$Ctx.Load($Ctx.Site) 

$Ctx.Load($Ctx.Web) 

$Ctx.ExecuteQuery() 

  

#Write-host -f Green "Site ID:"$Ctx.Site.Id 

  

#Write-host -f Green "Web ID:"$Ctx.Web.Id 

  

$CTX2 = $Ctx.Site.Id 

$CTX3 = $Ctx.Web.Id 

  

    #Setup the context 

    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL) 

    $Ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.UserName,$Cred.Password) 

      

    #Get the List 

    $List = $Ctx.Web.Lists.GetByTitle($ListName) 

    $Ctx.Load($List) 

    $Ctx.ExecuteQuery() 

  

    #Get List GUID 

    #Write-host -f Green $List.Id 

    $CTX4 = $List.id 

  

  

$String="tenantId=$TenantID&siteid={$Ctx2}&webId={$Ctx3}&listId=$CTX4&weburl=$Siteurl&version=1" 

  

$CSV = "$Title;$String;$SiteURL" 

  

$Csv |Out-File "$env:USERPROFILE\Desktop\OneDriveSync.csv" -Append 

  

  

} 