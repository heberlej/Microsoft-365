##############################################################################################################################################################
##############################################################################################################################################################
##############################################################################################################################################################
###########################################################################    GUI     #######################################################################
##############################################################################################################################################################
##############################################################################################################################################################
##############################################################################################################################################################
""
""
$ProgramVersion = "Make Me Admin Azure"
$Beschreibung = "LAPS Password reader"
"#######################"
"### $ProgramVersion ###"
"#######################"

# Install .Net Assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

# WinForm Setup
################################################################## Objects
# Main Form .Net Objects
$mainForm         = New-Object System.Windows.Forms.Form
$menuMain         = New-Object System.Windows.Forms.MenuStrip
$menuFile         = New-Object System.Windows.Forms.ToolStripMenuItem
$menuTools        = New-Object System.Windows.Forms.ToolStripMenuItem
$menuOptions      = New-Object System.Windows.Forms.ToolStripMenuItem
$menuOptions1     = New-Object System.Windows.Forms.ToolStripMenuItem
$menuOptions2     = New-Object System.Windows.Forms.ToolStripMenuItem
$menuExit         = New-Object System.Windows.Forms.ToolStripMenuItem
$menuSonkon       = New-Object System.Windows.Forms.ToolStripMenuItem
$menuStdkon       = New-Object System.Windows.Forms.ToolStripMenuItem
$menuLinkMSP      = New-Object System.Windows.Forms.ToolStripMenuItem
$menuHelp         = New-Object System.Windows.Forms.ToolStripMenuItem
$menuAbout        = New-Object System.Windows.Forms.ToolStripMenuItem
$statusStrip      = New-Object System.Windows.Forms.StatusStrip
$statusLabel      = New-Object System.Windows.Forms.ToolStripStatusLabel
$textfeld         = New-Object System.Windows.Forms.TextBox



$WelcomeAndDownloadAdvice  = New-Object System.Windows.Forms.Label
$ImportButton = New-Object System.Windows.Forms.Button
$Abschickbutton   = New-Object System.Windows.Forms.Button
$APIAbrufErfolgreichICON = New-Object System.Windows.Forms.PictureBox
$APIAbrufErfolgreichICON2 = New-Object System.Windows.Forms.PictureBox
$APIAbrufErfolgreichICON3 = New-Object System.Windows.Forms.PictureBox
$SavedAusgewahltHaken = New-Object System.Windows.Forms.PictureBox
$CSVNichtAusgewahltHaken = New-Object System.Windows.Forms.PictureBox
$LadeBalken = New-Object System.Windows.Forms.ProgressBar
$ShowRightButton = New-Object System.Windows.Forms.Button
$PrufungsHinweis = New-Object System.Windows.Forms.Label
$PrufungsHinweis20 = New-Object System.Windows.Forms.Label
$ShowRightZeilen = New-Object System.Windows.Forms.Button
$ShowWrongZeilen = New-Object System.Windows.Forms.Button
$ShowWrongZeilen = New-Object System.Windows.Forms.Label
$ExportRightZeilen = New-Object System.Windows.Forms.Button
$DatumAuswahl = New-Object system.Windows.Forms.ComboBox


################################################################## Icons
# WinForms Icons
# Create Icon Extractor Assembly
$code = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;

namespace System
{
	public class IconExtractor
	{

	 public static Icon Extract(string file, int number, bool largeIcon)
	 {
	  IntPtr large;
	  IntPtr small;
	  ExtractIconEx(file, number, out large, out small, 1);
	  try
	  {
	   return Icon.FromHandle(largeIcon ? large : small);
	  }
	  catch
	  {
	   return null;
	  }

	 }
	 [DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
	 private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);

	}
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing

# Extract PowerShell Icon from PowerShell Exe
$iconPS   = [Drawing.Icon]::ExtractAssociatedIcon((Get-Command powershell).Path)

################################################################## Main Form Setup
# Main Form
$mainForm.Height          = 500
$mainForm.Icon            = $iconPS
$mainForm.Width           = 350
$mainForm.StartPosition   = "CenterScreen"
$mainForm.Text            = $ProgramVersion
$mainForm.BackColor       = "White"
$mainForm.Controls.Add($menuMain)

################################################################## Main Menu
# Main Menu Bar
[void]$mainForm.Controls.Add($menuMain)

# Menu Options - File
$menuFile.Text = "&Datei"
[void]$menuMain.Items.Add($menuFile)

# Menu Options - File / Exit
$menuExit.Image        = [System.IconExtractor]::Extract("shell32.dll", 10, $true)
$menuExit.ShortcutKeys = "Control, X"
$menuExit.Text         = "&Exit"
$menuExit.Add_Click({$mainForm.Close()})
[void]$menuFile.DropDownItems.Add($menuExit)


# Menu Options - Tools
$menuTools.Text      = "&Optionen"
[void]$menuMain.Items.Add($menuTools)


# Menu Options - Tools / Options / Options 1
$menuOptions1.Image     = [System.IconExtractor]::Extract("shell32.dll", 33, $true)
$menuOptions1.Text      = "&Fehler korrigieren..."
$menuOptions1.Add_Click({API-Ablauf})
[void]$menuOptions.DropDownItems.Add($menuOptions1)

# Menu Options - Tools / Options / Options 2
$menuOptions2.Image     = [System.IconExtractor]::Extract("shell32.dll", 35, $true)
$menuOptions2.Text      = "&Systemvorraussetzungen prufen..."
$menuOptions2.Add_Click({Systemchecker})
[void]$menuOptions.DropDownItems.Add($menuOptions2)

# Menu Options - Help
$menuHelp.Text      = "&Hilfe"
[void]$menuMain.Items.Add($menuHelp)

# Menu Options - Help / About
$menuAbout.Image     = [System.Drawing.SystemIcons]::Information
$menuAbout.Text      = "uber $ProgramVersion"
$menuAbout.Add_Click({About})
[void]$menuHelp.DropDownItems.Add($menuAbout)


################################################################## Mainwindow
#Willkommen und CSV-Download-Hinweis (Step 1)
$WelcomeAndDownloadAdvice.Text = "Willkommen bei $ProgramVersion!`n`n1. Bitte wahlen Sie Ihren Laptop Namen aus ,`n     Der Benutzer heißt .\lapsadmin"
$WelcomeAndDownloadAdvice.Location  = New-Object System.Drawing.Point(10,35)
$WelcomeAndDownloadAdvice.AutoSize = $True
[void]$mainForm.Controls.Add($WelcomeAndDownloadAdvice)

#Liste fur Clientauswahl
$hostname = hostname
$DatumAuswahl.Location = New-Object System.Drawing.Size(26,95)
$DatumAuswahl.Size = New-Object System.Drawing.Size(140,23)
$DatumAuswahl.DropDownStyle = "DropDownList"
@("$hostname","PC-TEST01") | ForEach-Object {[void] $DatumAuswahl.Items.Add($_)}
[void]$mainForm.Controls.Add($DatumAuswahl)


#Liste fur Textfeld
$Beschreibung = New-Object System.Windows.Forms.Label
$Beschreibung.Text = "3. Bitte geben Sie den Grund fur den Admin Zugang ein !"
$Beschreibung.Location = New-Object System.Drawing.Size(10,160)
$Beschreibung.AutoSize = $True 
[void]$mainForm.Controls.Add($Beschreibung)
$textfeld.Location = New-Object System.Drawing.Size(26,180)
$textfeld.Size = New-Object System.Drawing.Size(140,23)
$textfeld.Text = "Grund"
$textfeld.AutoSize = $True
[void]$mainForm.Controls.Add($textfeld)


$Abschickbutton.Location = New-Object System.Drawing.Size(170,180)
$Abschickbutton.Size = New-Object System.Drawing.Size(110,23)
$Abschickbutton.Text = "Grund abschicken"
$mainForm.Controls.Add($Abschickbutton)


#Bei Klick auf $ImportButton den Dateien-Explorer fur CSV-Import öffnen
$Abschickbutton.Add_Click({
   
   
    Write-Host "Text wirg geteilt"
    $mainForm.Controls.Add($APIAbrufErfolgreichICON2)
}
)
#Button fur Auswahlsbestatigung des Datums
$ImportButton.Location = New-Object System.Drawing.Size(170,94)
$ImportButton.Size = New-Object System.Drawing.Size(110,23)
$ImportButton.Text = "Abrufen"
$mainForm.Controls.Add($ImportButton)

#Bei Klick auf $ImportButton den Dateien-Explorer fur CSV-Import öffnen
$ImportButton.Add_Click(
    {
        if($DatumAuswahl.SelectedItem -and $Abschickbutton )
        {

       ReadLapsPW
    
        } else {
        [System.Windows.Forms.MessageBox]::Show( "Fehler: Es wurde kein Client ausgewahlt. Bitte uberprufen Sie Ihre Eingabe!", "$ProgramVersion", "OK", "Error" )
        $mainForm.Controls.Add($CSVNichtAusgewahltHaken)
        }
    } 
)


#Hinweitext fur Export(Step 4) - GUI
$ExportHinweis = New-Object System.Windows.Forms.Label
$ExportHinweis.Text = "2. Anbei wird Ihnen das Passwort angezeigt"
$ExportHinweis.Location  = New-Object System.Drawing.Point(10,210)
$ExportHinweis.AutoSize = $True
[void]$mainForm.Controls.Add($ExportHinweis)


#Export Results (Step 3)
$ExportRightZeilen = New-Object System.Windows.Forms.Button
$ExportRightZeilen.Location = New-Object System.Drawing.Size(26,240)
$ExportRightZeilen.Size = New-Object System.Drawing.Size(285,23)
$ExportRightZeilen.Text = "Passwort anzeigen"
$ExportRightZeilen.Enabled = $True
$mainForm.Controls.Add($ExportRightZeilen)


#Bei Klick auf Button Export-Funktion starten (Step43)
$ExportRightZeilen.Add_Click(
    {

        if($LapsPW){
    #Hier wird ihr Passwort angezeigt
    
    $EndText = New-Object System.Windows.Forms.label
    $EndText.Location = New-Object System.Drawing.Size(10,280)
    $EndText.AutoSize = $True
    $EndText.Text = "4. Anbei wird Ihr Passwort angezeigt, das Passwort `n wurde auch automatisch in Ihre Zwischenablage gelegt"
    [void]$mainForm.Controls.Add($EndText)
    $mainForm.Controls.Add($APIAbrufErfolgreichICON3)


    #Export Results (Step 4)
    $FinishText = New-Object System.Windows.Forms.label
    $FinishText.Location = New-Object System.Drawing.Size(23,318)
    $FinishText.AutoSize = $True
    $FinishText.Text = $LapsPW
    [void]$mainForm.Controls.Add($FinishText)
    $LapsPW| clip
    }else {
        
#Variante 1
[System.Windows.Forms.MessageBox]::Show("Es wurde kein Passwort gefunden `nBitte wahlen Sie einen anderen Client aus  ","Error",[System.Windows.Forms.MessageBoxButtons]::OK)

    }

}
)
$CSVNichtAusgewahltHaken = New-Object System.Windows.Forms.PictureBox

#GrunerHakenWennAPIAbrufErfolgreich
$APIAbrufErfolgreichICON.ImageLocation = ".\BIN\Image\OK.png"
$APIAbrufErfolgreichICON.Location = New-Object System.Drawing.Size(280,90)
$APIAbrufErfolgreichICON.Size = New-Object System.Drawing.Size(335,23)
$APIAbrufErfolgreichICON.Height = 30
$APIAbrufErfolgreichICON.Width = 30
$APIAbrufErfolgreichICON2.ImageLocation = ".\BIN\Image\OK.png"
$APIAbrufErfolgreichICON2.Location = New-Object System.Drawing.Size(280,175)
$APIAbrufErfolgreichICON2.Size = New-Object System.Drawing.Size(335,23)
$APIAbrufErfolgreichICON2.Height = 30
$APIAbrufErfolgreichICON2.Width = 30
$APIAbrufErfolgreichICON3.ImageLocation = ".\BIN\Image\OK.png"
$APIAbrufErfolgreichICON3.Location = New-Object System.Drawing.Size(280,318)
$APIAbrufErfolgreichICON3.Size = New-Object System.Drawing.Size(335,23)
$APIAbrufErfolgreichICON3.Height = 30
$APIAbrufErfolgreichICON3.Width = 30


#GrunerHakenWennGespeichert
$SavedAusgewahltHaken.ImageLocation = ".\BIN\Image\OK.png"
$SavedAusgewahltHaken.Location = New-Object System.Drawing.Size(190,257)
$SavedAusgewahltHaken.Size = New-Object System.Drawing.Size(335,23)
$SavedAusgewahltHaken.Height = 30
$SavedAusgewahltHaken.Width = 30

#FehlerHakenWennNichtsAusgewahlt
$CSVNichtAusgewahltHaken.ImageLocation = ".\BIN\Image\No.png"
$CSVNichtAusgewahltHaken.Location = New-Object System.Drawing.Size(280,90)
$CSVNichtAusgewahltHaken.Size = New-Object System.Drawing.Size(335,23)
$CSVNichtAusgewahltHaken.Height = 30
$CSVNichtAusgewahltHaken.Width = 30

#LadeBalkoen
$LadeBalken.Location = New-Object System.Drawing.Size(23,130)
$LadeBalken.Size = New-Object System.Drawing.Size(285,23)
$LadeBalken.Value = 1
$LadeBalken.Minimum = 1
[void]$mainForm.Controls.Add($LadeBalken)

################################################################## Status Bar
# Status Bar & Label
[void]$statusStrip.Items.Add($statusLabel)
$statusLabel.AutoSize  = $true
$statusLabel.Text      = $Beschreibung
$mainForm.Controls.Add($statusStrip)

################################################################## Functions
function About {
    $statusLabel.Text = "uber"
    # About Form Objects
    $aboutForm          = New-Object System.Windows.Forms.Form
    $aboutFormExit      = New-Object System.Windows.Forms.Button
    $aboutFormImage     = New-Object System.Windows.Forms.PictureBox
    $aboutFormNameLabel = New-Object System.Windows.Forms.Label
    $aboutFormText      = New-Object System.Windows.Forms.Label

    # About Form
    $aboutForm.AcceptButton  = $aboutFormExit
    $aboutForm.CancelButton  = $aboutFormExit
    $aboutForm.ClientSize    = "350, 110"
    $aboutForm.ControlBox    = $false
    $aboutForm.ShowInTaskBar = $false
    $aboutForm.StartPosition = "CenterParent"
    $aboutForm.Text          = "uber $ProgramVersion"
    $aboutForm.Add_Load($aboutForm_Load)

    # About PictureBox
    $aboutFormImage.Image    = $iconPS.ToBitmap()
    $aboutFormImage.Location = "55, 15"
    $aboutFormImage.Size     = "32, 32"
    $aboutFormImage.SizeMode = "StretchImage"
    $aboutForm.Controls.Add($aboutFormImage)

    # About Name Label
    $aboutFormNameLabel.Font     = New-Object Drawing.Font("Microsoft Sans Serif", 9, [System.Drawing.FontStyle]::Bold)
    $aboutFormNameLabel.Location = "110, 20"
    $aboutFormNameLabel.Size     = "400, 18"
    $aboutFormNameLabel.Text     = $Beschreibung
    $aboutForm.Controls.Add($aboutFormNameLabel)

    # About Text Label
    $aboutFormText.Location = "150, 40"
    $aboutFormText.Size     = "300, 30"
    $aboutFormText.Text     = "Jan Heberle `n`r $ProgramVersion"
    $aboutForm.Controls.Add($aboutFormText)

    # About Exit Button
    $aboutFormExit.Location = "135, 70"
    $aboutFormExit.Text     = "OK"
    $aboutForm.Controls.Add($aboutFormExit)

    [void]$aboutForm.ShowDialog()
    $statusLabel.Text = $Beschreibung
} # End About

################################################################## Functions

################################################################## Functions
function ReadLapsPW {
$ladebalken.Maximum = 10
$mainForm.Controls.Remove($APIAbrufErfolgreichICON)

$LadeBalken.Value = 1
   
    # The following command only required one time execution
if ( Get-ExecutionPolicy)
{
   
Write-Host "RemoteSigned policy exists."
}
else
{
Write-Host "RemoteSigned policy does not exist."
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
}

if (Get-Module -ListAvailable -Name Microsoft.Graph) {
Write-Host "Microsoft.Graph Module exists"
$LadeBalken.Value = 2
} 
else {
Write-Host "Microsoft.Graph Module does not exist"
Install-Module Microsoft.Graph -Scope AllUsers
}

# Populate with the App Registration details and Tenant ID
$ClientId          = "<CLIENT-ID>"
$ClientSecret      = "<CLIENT-SECRET>" 
$tenantid          = "<TENANT-ID>" 
$GraphScopes       = "https://graph.microsoft.com/.default"
$LadeBalken.Value = 3

$headers = @{
"Content-Type" = "application/x-www-form-urlencoded"
}
$LadeBalken.Value = 4
$body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&scope=https%3A%2F%2Fgraph.microsoft.com%2F.default"
$authUri = "https://login.microsoftonline.com/$tenantid/oauth2/v2.0/token"
$response = Invoke-RestMethod $authUri  -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json

$token = $response.access_token #ConvertTo-SecureString($response.access_token) -AsPlainText -Force 
$LadeBalken.Value = 5
# Authenticate to the Microsoft Graph
Connect-MgGraph -AccessToken $token


$LadeBalken.Value = 6
# If you want to see debugging output of the command just add "-Debug" to the call.
$DeviceName = $DatumAuswahl.SelectedItem #hostname
$DeviceName
#Store the device id value for your target device
$DeviceId = (Get-MgDevice | Where-Object {$_.DisplayName -eq $DeviceName} | Select DeviceId).DeviceId
$LadeBalken.Value = 7
#Generate a new correlation ID
$correlationID = [System.Guid]::NewGuid()
$LadeBalken.Value = 8
#Define the URI path
$uri = 'beta/deviceLocalCredentials/' + $DeviceId
$uri = $uri + '?$select=credentials'

#Build the request header
$headers = @{}
$headers.Add('ocp-client-name', 'Get-LapsAADPassword Windows LAPS Cmdlet')
$headers.Add('ocp-client-version', '1.0')
$headers.Add('client-request-id', $correlationID)

#Initation the request to Microsoft Graph for the LAPS password
$Response = Invoke-MgGraphRequest -Method GET -Uri $URI -Headers $headers
$LadeBalken.Value = 9
#Decode the LAPS password from Base64
$passwordb64 = ($Response.credentials).PasswordBase64


$temp = $passwordb64 | %{[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_))}

$LapsPW =  $temp 
$LadeBalken.Value = 10
$mainForm.Controls.Add($APIAbrufErfolgreichICON)


}

# Show Main Form
[void] $mainForm.ShowDialog()