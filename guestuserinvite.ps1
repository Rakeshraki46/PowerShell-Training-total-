Connect-MgGraph -Scopes "User.Invite.All"
$customerEmail = "rakesh.joruka9999@gmail.com"
$redirectUrl = "https://microsoft.com"

$invitedUser = New-MgInvitation `
    -InvitedUserDisplayName "External Guest User" `
    -InvitedUserEmailAddress $customerEmail `
    -InviteRedirectUrl $redirectUrl `
    -SendInvitationMessage

Write-Host "Invite status: $($invitedUser.Status)"
Write-Host "Invite object: $($invitedUser | ConvertTo-Json -Depth 10)"
