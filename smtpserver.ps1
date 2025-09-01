# ==== CONFIGURATION ====
$from = "rakesh.joruka9999@gmail.com"  # Your Gmail address
$subject = "Your Manufacturing Account Details"
$smtpServer = "smtp.gmail.com"
$smtpPort = 587
$hyperlink = "https://mail.google.com/"  # Gmail-specific hyperlink for test
$csvPath = "C:\Users\Administrator\Downloads\gmail_user_data.csv"  # Your CSV path

# ==== LOAD CSV ====
if (-not (Test-Path $csvPath)) {
    Write-Error "❌ CSV file not found: $csvPath"
    exit
}

$csvData = Import-Csv $csvPath

if (-not $csvData) {
    Write-Error "❌ CSV is empty or improperly formatted."
    exit
}

# ==== PROMPT FOR APP PASSWORD ====
$credential = Get-Credential  # Use Gmail + App Password

# ==== LOOP AND SEND EMAIL ====
foreach ($user in $csvData) {
    $firstname = $user.givenName
    $lastname = $user.surname
    $username = $user.userPrincipalName
    $to = $user.mail

    $body = @"
<html>
  <body style='font-family:Arial, sans-serif; font-size:14px;'>
    <p>Hello $firstname $lastname,</p>
    <p>rakesh is a good and angry men so dont leave him <b>$firstname</b></p>
    
    <p>Please visit our <a href='$hyperlink'>Gmail Inbox</a> to check your mail or access services.</p>
    <p>Good Luck <b>$firstname</b></p>
  </body>
</html>
"@

    try {
        Send-MailMessage -From $from -To $to -Subject $subject -Body $body `
            -BodyAsHtml -SmtpServer $smtpServer -Port $smtpPort -UseSsl `
            -Credential $credential

        Write-Output "✅ Email sent to $to"
    }
    catch {
        Write-Error "❌ Failed to send to $to. Error: $_"
    }
}
