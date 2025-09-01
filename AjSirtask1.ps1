# Set variables
#$tenantId = "bb331774-9480-4444-97dc-73dcf1507c51"
#$clientId = "728ea2c4-6001-44f5-8e78-56f11efbc2cf"
#$clientSecret = "rAu8Q~A-rKphbhSEEXuJQ4mKcN5pm_2O3hKDJds7"
#$authority = "https://login.microsoftonline.com/$tenantId"
#$scope = "https://graph.microsoft.com/.default"

# Create the authentication body
$body = @{
    client_id     = $clientId
    scope         = $scope
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

# Get the OAuth token
$tokenResponse = Invoke-RestMethod -Uri "$authority/oauth2/v2.0/token" -Method Post -ContentType "application/x-www-form-urlencoded" -Body $body

# Extract the access token
$accessToken = $tokenResponse.access_token

# Use the access token for Microsoft Graph API requests
$headers = @{
    Authorization = "Bearer $accessToken"
}

# Example Graph API call to get users
$uri = "https://graph.microsoft.com/v1.0/users"
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

# Output the response
Write-Output "$response.value"
