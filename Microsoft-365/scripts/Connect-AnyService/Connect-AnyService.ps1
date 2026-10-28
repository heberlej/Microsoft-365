# Laden der benötigten Module 

#Import-Module ActiveDirectory 

#Import-Module ExchangeOnlineManagement 

#Import-Module Msolservice 

#Import-Module AzureAD 

Add-Type -AssemblyName System.Windows.Forms 

 

# Erstellen des Hauptfensters der GUI 

$Form = New-Object System.Windows.Forms.Form 

$Form.Text = "Service ausw�hlen" 

$Form.Size = New-Object System.Drawing.Size(400, 400) 

 

# Erstellen der Liste für die Benutzeranzeige 

$UserList = New-Object System.Windows.Forms.CheckedListBox 

$UserList.Location = New-Object System.Drawing.Point(10, 10) 

$UserList.Size = New-Object System.Drawing.Size(300, 300) 

$Form.Controls.Add($UserList) 

 

# Schaltfläche zum Auswählen der Benutzer 

$SelectButton = New-Object System.Windows.Forms.Button 

$SelectButton.Location = New-Object System.Drawing.Point(10, 320) 

$SelectButton.Size = New-Object System.Drawing.Size(100, 30) 

$SelectButton.Text = "Auswählen" 

$Form.Controls.Add($SelectButton) 

 

# Schaltfläche zum Schließen der GUI 

$CloseButton = New-Object System.Windows.Forms.Button 

$CloseButton.Location = New-Object System.Drawing.Point(120, 320) 

$CloseButton.Size = New-Object System.Drawing.Size(100, 30) 

$CloseButton.Text = "Schließen" 

$Form.Controls.Add($CloseButton) 


# Ereignis zum Laden der Benutzerliste 

$Form.Add_Load({ 

    $ADUsers =@("Connect-ExchangeOnline","Connect-Msolservice","Connect-AzureAD","Connect-Mggraph","Connect-pnponline","Connect-MicrosoftTeams") 

    foreach ($User in $ADUsers) { 

        $UserList.Items.Add($User) 

    } 

}) 

 

# Ereignis zum Auswählen der Benutzer 

$SelectButton.Add_Click({ 

    $SelectedUsers = @() 

    foreach ($Item in $UserList.CheckedItems) { 

        $SelectedUsers += $Item 

    } 

    $Form.Tag = $SelectedUsers 

    $Form.Close() 

}) 

 

# Ereignis zum Schließen der GUI 

$CloseButton.Add_Click({ 

    $Form.Tag = $null 

    $Form.Close() 

}) 

 

# Anzeigen der GUI 

$Form.ShowDialog() 

 

# Die ausgewählten Benutzer sind in $Form.Tag gespeichert 

$SelectedUsers = $Form.Tag 

 

# Ausgabe der ausgewählten Benutzer 

if ($SelectedUsers -eq "Connect-ExchangeOnline") { 

    Write-Host "Ausgewählter Service :" $SelectedUsers 

    $SelectedUsers | ForEach-Object { 

        Connect-ExchangeOnline 

    } 

} if ($SelectedUsers -eq "Connect-MsolService") { 

    Write-Host "Ausgewählter Service :" $SelectedUsers 

    $SelectedUsers | ForEach-Object { 

        Connect-Msolservice 

    } 

}if ($SelectedUsers -eq "Connect-AzureAD") { 

    Write-Host "Ausgewählter Service :" $SelectedUsers 

    $SelectedUsers | ForEach-Object { 

        Connect-AzureAD 
        }

}if ($SelectedUsers -eq "Connect-MicrosoftTeams"){

    Write-Host "Ausgewählter Service :" $SelectedUsers 

    $SelectedUsers | ForEach-Object { 

        Connect-MicrosoftTeams

} 
}
 

 

 

if ($SelectedUsers -eq "Connect-Mggraph") { 

    Write-Host "Ausgewählter Service :" $SelectedUsers 

    # Laden der benötigten Module 

 

 

Add-Type -AssemblyName System.Windows.Forms 

 

# Erstellen des Hauptfensters der GUI 

$Forms = New-Object System.Windows.Forms.Form 

$Forms.Text = "Benutzer auswählen" 

$Forms.Size = New-Object System.Drawing.Size(400, 400) 

 

# Erstellen der Liste für die Benutzeranzeige 

$UserLists = New-Object System.Windows.Forms.CheckedListBox 

$UserLists.Location = New-Object System.Drawing.Point(10, 10) 

$UserLists.Size = New-Object System.Drawing.Size(300, 300) 

$Forms.Controls.Add($UserLists) 

 

# Schaltfläche zum Auswählen der Benutzer 

$SelectButtons = New-Object System.Windows.Forms.Button 

$SelectButtons.Location = New-Object System.Drawing.Point(10, 320) 

$SelectButtons.Size = New-Object System.Drawing.Size(100, 30) 

$SelectButtons.Text = "Auswählen" 

$Forms.Controls.Add($SelectButtons) 

 

# Schaltfläche zum Schließen der GUI 

$CloseButtons = New-Object System.Windows.Forms.Button 

$CloseButtons.Location = New-Object System.Drawing.Point(120, 320) 

$CloseButtons.Size = New-Object System.Drawing.Size(100, 30) 

$CloseButtons.Text = "Schließen" 

$Forms.Controls.Add($CloseButtons) 

 

# Ereignis zum Laden der Benutzerliste 

$Forms.Add_Load({ 

    $ADUserss = @( 

    "Chat.ReadWrite.All" 

    "Directory.Read.All" 

    "Group.Read.All" 

    "Mail.ReadWrite" 

    "People.Read.All" 

    "Sites.Manage.All" 

    "User.Read.All" 

    "User.ReadWrite.All" 

) 

    foreach ($User in $ADUserss) { 

        $UserLists.Items.Add($User) 

    } 

}) 

 

# Ereignis zum Auswählen der Benutzer 

$SelectButtons.Add_Click({ 

    $SelectedUserss = @() 

    foreach ($Item in $UserLists.CheckedItems) { 

        $SelectedUserss += $Item 

    } 

    $Forms.Tag = $SelectedUserss 

    $Forms.Close() 

}) 

 

# Ereignis zum Schließen der GUI 

$CloseButtons.Add_Click({ 

    $Forms.Tag = $null 

    $Forms.Close() 

}) 

 

# Anzeigen der GUI 

$Forms.ShowDialog() 

 

# Die ausgewählten Benutzer sind in $Form.Tag gespeichert 

$SelectedUserss = $Forms.Tag 

 

 

    $SelectedUsers | ForEach-Object { 

        Connect-Mggraph -Scopes $SelectedUserss 

    } 

} 

 

 

if ($SelectedUsers -eq "Connect-pnponline") { 

    Write-Host "Ausgewählter Service :" $SelectedUsers 

    $SelectedUsers | ForEach-Object { 

        Connect-pnponline 

    } 

}else { 

    Write-Host "Keine Benutzer ausgewählt." 

} 