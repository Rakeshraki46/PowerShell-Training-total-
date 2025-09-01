############################################
# 1) Connect to Microsoft Graph
############################################
Connect-MgGraph -Scopes "Application.ReadWrite.All","Directory.ReadWrite.All","Policy.ReadWrite.ApplicationConfiguration"

############################################
# 2) Create a new SAML application
############################################
$displayName = "madrid-100128"

Write-Host "Creating a new SAML application '$displayName'..."

# Find a SAML template
$template = Get-MgApplicationTemplate -All |
    Where-Object { $_.Categories -contains "SAML" } |
    Select-Object -First 1

if (-not $template) {
    # Fallback by name
    $template = Get-MgApplicationTemplate -All |
        Where-Object { $_.DisplayName -like "*SAML*" } |
        Select-Object -First 1
}
if (-not $template) { Throw "ERROR: No SAML template found in Graph." }

# Create a new SAML application using the template
$body = @{ displayName = $displayName } | ConvertTo-Json
$result = Invoke-MgGraphRequest -Method POST -Uri "/beta/applicationTemplates/$($template.Id)/instantiate" -Body $body

$appId = $result.application.appId
Write-Host "Created AppRegistration (AppId = $appId)"

# Wait for AppRegistration
$appObj = $null
for ($i = 0; $i -lt 12; $i++) {
    $found = Get-MgApplication -Filter "appId eq '$appId'" -ErrorAction SilentlyContinue
    if ($found) { $appObj = $found; break }
    Start-Sleep -Seconds 5
}
if (-not $appObj) { Throw "Timed out waiting for AppRegistration to appear in Graph." }
$appObjectId = $appObj.Id

# Wait for ServicePrincipal
$spObj = $null
for ($i = 0; $i -lt 12; $i++) {
    $foundSP = Get-MgServicePrincipal -Filter "appId eq '$appId'" -ErrorAction SilentlyContinue
    if ($foundSP) { $spObj = $foundSP; break }
    Start-Sleep -Seconds 5
}
if (-not $spObj) { Throw "Timed out waiting for ServicePrincipal to appear in Graph." }
$spObjectId = $spObj.Id

Write-Host "Created AppRegistration (AppId = $appId)"

############################################
# 3) Define your URLs
############################################
#$entityId    ="https://verizon038.onmicrosoft.com/madrid-100125"  # ✅ Fixed (no path)
$entityId = "https://us-region2-tc-tpdbos1.devgateway.verizon.com/metadata"
$replyUrl    = "https://us.region-2c-tpdbos1.devgateway.verizon.com/secure_access/services/saml/login-consumer"
$signOnUrl   =  "https://us.region-2c-tpdbos1.devgateway.verizon.com/secure_access/services/saml/login-consumer"

############################################
# 4) Set Entity ID (identifierUris)
############################################
try {
    Update-MgApplication -ApplicationId $appObjectId -BodyParameter @{
        identifierUris = @($entityId)
    }
    Write-Host "✅ Set Entity ID (identifierUris) on AppRegistration."
}
catch {
    Write-Warning "⚠ Failed to set Entity ID. Make sure the domain is verified and has no path."
    Write-Warning $_
}

############################################
# 5) Set the samlMetadataUrl
############################################
Update-MgApplication -ApplicationId $appObjectId -BodyParameter @{
    samlMetadataUrl = $identityUrl
}
Write-Host "Set samlMetadataUrl on AppRegistration."

############################################
# 6) Set Reply URL (ACS)
############################################
Update-MgApplication -ApplicationId $appObjectId -BodyParameter @{
    web = @{
        redirectUris = @($replyUrl)
    }
}
Write-Host "Set Reply URL on AppRegistration."

############################################
# 7) Configure the Service Principal
############################################
Update-MgServicePrincipal -ServicePrincipalId $spObjectId -BodyParameter @{
    preferredSingleSignOnMode = "saml"
    loginUrl                  = $signOnUrl
    samlSingleSignOnSettings  = @{ relayState = $replyUrl }
}
Write-Host "Configured ServicePrincipal for direct SAML SSO."

############################################
# 8) Generate Token Signing Certificate
############################################
$certResp = Invoke-MgGraphRequest -Method POST `
    -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$spObjectId/addTokenSigningCertificate" `
    -Body (@{
        displayName = "CN=$displayName SAML Signing"
        endDateTime = (Get-Date).AddYears(2).ToString("o")
    } | ConvertTo-Json)

Write-Host "Certificate thumbprint: $($certResp.thumbprint)"

############################################
# 9) Output Metadata URL
############################################
$federationMetadataUrl = "https://login.microsoftonline.com/$appId/federationmetadata/2007-06/federationmetadata.xml?appid=$appId"
Write-Host "`n✅ SAML app '$displayName' is ready!"
Write-Host "Federation Metadata URL:"
Write-Host "  $federationMetadataUrl"
