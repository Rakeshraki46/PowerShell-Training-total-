#Step 1:Defining the app registration details
$tenantId = "bb331774-9480-4444-97dc-73dcf1507c51"
$clientId = "14d0ac9d-4881-4092-baf9-fe2c2798028d"
$clientSecret = "yGo8Q~ceDfIYoAXAsQ.VzHgfJbVd6b5wR9PukasC"
#Step 2: Setting the default scope
$scope = "https://graph.microsoft.com/.default" 
#Step 3: Define the URL for the token endpoint
$tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

#Step 4: Define the body of the request
$body = @{
    client_id     = $clientId
    scope         = $scope
    client_secret = $clientSecret
    grant_type    = "client_credentials" #what is it?what else it can be
}
#Step 5: Calling the token endpoint and storing the response
$Response = Invoke-RestMethod -Uri $tokenEndpoint -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"  # understand this  what are some oter values can be set in content type

#Step 6: Defining the Graph endpoint
$GraphEndpoint = "https://graph.microsoft.com/v1.0/users"

#Step 7: Defining the Headers and using the access token from $Response
$Headers = @{  # tcp/ip protocol understand the structure of packet
    Authorization = "Bearer $($Response.access_token)"## holds information about the connection and the current data being sent. The 10 TCP header fields are as follows: Source port – The sending device's port. Destination port 
    ContentType   = "application/json"  # difference between line 18 and 25

}
#Step 8: Calling the Graph endpoint and storing the response
$GraphResponse = Invoke-RestMethod -Uri $GraphEndpoint -Method Get -Headers $Headers  
$GraphResponse.value

$filteredResponse = $GraphResponse.value | Select-Object Id , createdDateTime , displayName  , description , MailNickName ,mail
Write-Output $filteredResponse
$totalCount = $filteredResponse.Count
Write-Output "Total Count: $totalCount"

#New-AzureADUser -DisplayName "vivek" -UserPrincipalName "vivek@MegThink582.onmicrosoft.com" -PasswordProfile (New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile -ArgumentList "P@ssw0rd")  -GivenName "vivek" -Surname "ajay" -MailNickName "vivekajay"
# above command says how to create users in Entraid using powershell
#Get-AzureADUser | Where-Object { $_.UserPrincipalName -eq "johndoe@MegThink582.onmicrosoft.com" }
#show id ,
######################################################################################################

$users = Import-Csv -Path "C:\Users\Rakesh\Downloads\NewUsers.csv" #function #cmdlets in ps or fun
foreach ($user in $users){
    Write-Host "Creating user: $($user.DisplayName)"
    $userParams1 =@{
        DisplayName       = $User.DisplayName
        MailNickName      = $User.MailNickName
        UserPrincipalName = $User.UserPrincipalName
        PasswordProfile   = $PasswordProfile
        AccountEnabled    = $true
        }
    }
    $PasswordProfile = @{
        Password = "P@ssw0rd!"  
    
    }  
   
        New-MgUser @userParams1
        Write-Host "User $($user.DisplayName) created successfully." -ForegroundColor Green
   