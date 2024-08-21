param(
    [Parameter(Mandatory=$true)]
    [string]$username,
    [Parameter(Mandatory=$true)]
    [string]$fullname,
    [Parameter(Mandatory=$true)]
    [string]$email,
    [Parameter(Mandatory=$true)]
    [string]$AutomationPassword
    )

#In case they put ; instead of , in the email field
$email = $email.Replace(';',',')

#Generate random password
function Get-RandomCharacters($length, $characters) { 
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length } 
    $private:ofs="" 
    return [String]$characters[$random]
}

$password = Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
$password += Get-RandomCharacters -length 1 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
$password += Get-RandomCharacters -length 1 -characters '1234567890'
$password += Get-RandomCharacters -length 1 -characters '!$%&/()=?}][{@#*+'

#variables
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$uri = ""

#Get token
$tokenbody = @{
    grant_type = "password"
    username = "AutomationUsername"
    password = $AutomationPassword
    }
$tokenresponse = Invoke-WebRequest -UseBasicParsing -Uri "$uri/token" -Method POST -ContentType "application/x-www-form-urlencoded" -Body $tokenbody

$tokenresponse = $tokenresponse | ConvertFrom-Json
$token = $tokenresponse | select -ExpandProperty access_token

#Create Selerix user
#Variables
$body = @{
    sourceUserId = ""     #UserId for the template to clone from      
    username = "$username"
    fullname = "$fullname"
    password = "$password"
    email = "$email"
    permission = "User"
    forceChangePassword = 'true'
    homeFolderPath = "Home/$username/"
    homeFolderInUseOption = "AllowIfExists"
    emailFormat = "HTML"    
    }
$headers = @{
    Authorization = "Bearer $token"
    }

#Create user       
$response = Invoke-WebRequest -UseBasicParsing -Uri "$uri/users/" -Method POST -Headers $headers -ContentType "application/json" -Body ($body | ConvertTo-Json) | ConvertFrom-Json

#Get user ID to change default folder path
$id = $response.id

#Change Default folder to match Home folder
#Variables
$Body = @{
    defaultFolderId = "0"
    }

#Change default folder path
$response1 = Invoke-WebRequest -UseBasicParsing -Uri "$uri/users/$id" -Method PATCH -Headers $headers -ContentType "application/json" -Body ($body | ConvertTo-Json) | ConvertFrom-Json

#Send email to user just created
#variables
#replace commas with semi-colons and split them
$to = $email.Replace(',',';')
$to = $to.split(';')

$From = ""
$Subject = "New User Account created from MOVEit"
$smtp = ""   #Smtp server

$Body = @"
<html xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" xmlns:m="http://schemas.microsoft.com/office/2004/12/omml" xmlns="http://www.w3.org/TR/REC-html40"><head><meta http-equiv=Content-Type content="text/html; charset=us-ascii"><meta name=Generator content="Microsoft Word 15 (filtered medium)"><!--[if !mso]><style>v\:* {behavior:url(#default#VML);}
o\:* {behavior:url(#default#VML);}
w\:* {behavior:url(#default#VML);}
.shape {behavior:url(#default#VML);}
</style><![endif]--><style><!--
/* Font Definitions */
@font-face
	{font-family:"Cambria Math";
	panose-1:2 4 5 3 5 4 6 3 2 4;}
@font-face
	{font-family:Calibri;
	panose-1:2 15 5 2 2 2 4 3 2 4;}
@font-face
	{font-family:"Calibri Light";
	panose-1:2 15 3 2 2 2 4 3 2 4;}
/* Style Definitions */
p.MsoNormal, li.MsoNormal, div.MsoNormal
	{margin:0in;
	margin-bottom:.0001pt;
	font-size:11.0pt;
	font-family:"Calibri",sans-serif;}
h1
	{mso-style-priority:9;
	mso-style-link:"Heading 1 Char";
	margin-top:12.0pt;
	margin-right:0in;
	margin-bottom:0in;
	margin-left:0in;
	margin-bottom:.0001pt;
	page-break-after:avoid;
	font-size:16.0pt;
	font-family:"Calibri Light",sans-serif;
	color:#2F5496;
	font-weight:normal;}
span.EmailStyle17
	{mso-style-type:personal-compose;
	font-family:"Calibri",sans-serif;
	color:windowtext;}
span.Heading1Char
	{mso-style-name:"Heading 1 Char";
	mso-style-priority:9;
	mso-style-link:"Heading 1";
	font-family:"Calibri Light",sans-serif;
	color:#2F5496;}
.MsoChpDefault
	{mso-style-type:export-only;
	font-family:"Calibri",sans-serif;}
@page WordSection1
	{size:8.5in 11.0in;
	margin:1.0in 1.0in 1.0in 1.0in;}
div.WordSection1
	{page:WordSection1;}
--></style><!--[if gte mso 9]><xml>
<o:shapedefaults v:ext="edit" spidmax="1026" />
</xml><![endif]--><!--[if gte mso 9]><xml>
<o:shapelayout v:ext="edit">
<o:idmap v:ext="edit" data="1" />
</o:shapelayout></xml><![endif]--></head><body lang=EN-US link="#0563C1" vlink="#954F72"><div class=WordSection1><p class=MsoNormal>
<h1>Welcome to MOVEit!<o:p></o:p></h1>
<p class=MsoNormal><o:p>&nbsp;</o:p></p><p class=MsoNormal>An account has been created for you with the username '<span style='color:#A82D00'>$username</span>'.<o:p></o:p></p>
<p class=MsoNormal>Your new credentials are:<o:p></o:p></p><p class=MsoNormal><o:p>&nbsp;</o:p></p>
<p class=MsoNormal>Username: <span style='color:#A82D00'>$username</span><o:p></o:p></p>
<p class=MsoNormal>Password: <span style='color:#A82D00'>$password</span><o:p></o:p></p>
<p class=MsoNormal><o:p>&nbsp;</o:p></p><p class=MsoNormal>If site policy requires it, at sign on you will be guided through additional steps to secure your account.<o:p></o:p></p>
<p class=MsoNormal><o:p>&nbsp;</o:p></p><p class=MsoNormal>Please use the following URL to sign on to the system.<o:p></o:p></p>
<p class=MsoNormal><o:p>&nbsp;</o:p></p><p class=MsoNormal>(  )<o:p></o:p></p>
<p class=MsoNormal><o:p>&nbsp;</o:p></p><p class=MsoNormal>If you need assistance, please contact Technical Support at&nbsp; .<o:p></o:p></p>
<p class=MsoNormal><b><span style='font-family:"Arial",sans-serif;color:#7F7F7F'><o:p>&nbsp;</o:p></span></b></p><p class=MsoNormal>Regards,<o:p></o:p></p>
<p class=MsoNormal><b><span style='font-family:"Arial",sans-serif;color:#7F7F7F'><o:p>&nbsp;</o:p></span></b></p>
<p class=MsoNormal><b><span style='font-family:"Arial",sans-serif;color:#7F7F7F'><o:p></o:p></span></b></p>
<p class=MsoNormal><b><span style='font-family:"Arial",sans-serif;color:#7F7F7F'><o:p>&nbsp;</o:p></span></b></p>
<p class=MsoNormal><img src="cid:MOVEitlogo.gif" ><span style='font-family:"Arial",sans-serif;color:#7F7F7F'><o:p></o:p></span></p></div></body></html>
"@

#Send email
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
Send-mailmessage -From $From -To $To -Subject $Subject -Body $body -BodyAsHtml -SmtpServer $smtp -UseSsl -Attachments "E:\Moveit\MOVEitlogo.gif"