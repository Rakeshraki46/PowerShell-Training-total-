#$clientId = "728ea2c4-6001-44f5-8e78-56f11efbc2cf"
#$tenantId = "bb331774-9480-4444-97dc-73dcf1507c51"
#$clientSecret = "rAu8Q~A-rKphbhSEEXuJQ4mKcN5pm_2O3hKDJds7"

$secureClientSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force

$credentials = New-Object Microsoft.Graph.PowerShell.Authentication.MSGraphClientCredential($clientId, $secureClientSecret, $tenantId)

Connect-MgGraph -ClientCredential $credentials
