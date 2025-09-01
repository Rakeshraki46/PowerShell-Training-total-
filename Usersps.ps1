connect-mggraph -scopes "user.readwrite.all"


$params = @{
	accountEnabled = $true
	displayName = "harshad"
	mailNickname = "AdeleV"
	userPrincipalName = "harshad@megthink582.onmicrosoft.com"
    department = "hr"
	passwordProfile = @{
		forceChangePasswordNextSignIn = $true
		password = "xWwvJ]6NMw+bWH-d"
	}
}

New-MgUser -BodyParameter $params