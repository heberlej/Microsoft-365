#Load Assemblies

[System.Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”) | Out-Null

[System.Reflection.Assembly]::LoadWithPartialName(“System.Drawing”) | Out-Null

$net = New-Object -ComObject Wscript.Network
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


$headers = @{
    "Content-Type" = "application/x-www-form-urlencoded"
}

$body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&scope=https%3A%2F%2Fgraph.microsoft.com%2F.default"
$authUri = "https://login.microsoftonline.com/$tenantid/oauth2/v2.0/token"
$response = Invoke-RestMethod $authUri  -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json
 
$token = $response.access_token
 
# Authenticate to the Microsoft Graph
Connect-MgGraph -AccessToken $token

# If you want to see debugging output of the command just add "-Debug" to the call.
$DeviceName = hostname
#Store the device id value for your target device
$DeviceId = (Get-MgDevice | Where-Object {$_.DisplayName -eq $DeviceName} | Select DeviceId).DeviceId

#Generate a new correlation ID
$correlationID = [System.Guid]::NewGuid()

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

#Decode the LAPS password from Base64
$passwordb64 = ($Response.credentials).PasswordBase64
$LapsPW = $passwordb64 | %{[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_))}
 

#Define Button Click Function

Function DisplayVMs

{



Add-Type -AssemblyName System.Windows.Forms

#Create text

$Label = New-Object System.Windows.Forms.textbox

$Label.Location = new-object System.Drawing.Size(200,110)

$Label.Size = New-Object System.Drawing.Size(150,150)

$Label.MultiLine = $True

$NL = “`r`n”

Foreach ($vm in $LapsPW){

                $Label.Text = $Label.Text + $VM + $NL

                }

 

 $Form.Controls.Add($Label)

}

 

#Draw form

$Form = New-Object System.Windows.Forms.Form

 $Form.width = 525

 $Form.height = 350

 $Form.BackColor = “lightblue”

 $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D

 $Form.Text = “Administrator Kennwort”

 $Form.maximumsize = New-Object System.Drawing.Size(525,350)

 $Form.startposition = “centerscreen”

 $Form.KeyPreview = $True

 $Form.Add_KeyDown({if ($_.KeyCode -eq “Enter”) {}})

 $Form.Add_KeyDown({if ($_.KeyCode -eq “Escape”)

 {$Form.Close()}})

 

# Create Label2

$Label2 = New-Object System.Windows.Forms.Label

$Label2.AutoSize = $True

$Label2.Location = new-object System.Drawing.Size(20,50)

$Label2.ForeColor = “DarkBlue”

$Label2.Text = “Klicken Sie hier um Ihr Administrator Passwort anzuzeigen”

#Create button

 $Button1 = new-object System.Windows.Forms.Button

 $Button1.Location = new-object System.Drawing.Size(30,70)

 $Button1.Size = new-object System.Drawing.Size(80,20)

 $Button1.BackColor =”LightGray”

 $Button1.Text = “OK”

 $Button1.Add_Click({DisplayVMs})

#Create the Form

$Form.Controls.Add($Button1)

$Form.Controls.Add($Label2)

$Form.Add_Shown({$Form.Activate()})

$Form.ShowDialog()