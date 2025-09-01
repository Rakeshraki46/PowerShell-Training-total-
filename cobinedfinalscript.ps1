############################################
# 1) Connect to Microsoft Graph
############################################
Connect-MgGraph -Scopes "Application.ReadWrite.All","Directory.ReadWrite.All","Policy.ReadWrite.ApplicationConfiguration"

############################################
# 2) Define your variables
############################################
$displayName = "madrid-100181"   # Change as needed, must be unique

# IMPORTANT: Replace this with your tenant's verified domain
# Example: https://contoso.onmicrosoft.com/madrid-100180
#$entityId    = "https://yourverifieddomain.onmicrosoft.com/madrid-100180" 

$identityUrl = "https://us-region2-tc-tpdbos1.devgateway.verizon.com/metadata"
$replyUrl    = "https://us-region2-tc-tpdbos1.devgateway.verizon.com/secure-access/services/sami/login-consumer"
$signOnUrl   = $replyUrl
$relayState  = $replyUrl

############################################
# 3) Check if application exists
############################################
$appObj = Get-MgApplication -Filter "displayName eq '$displayName'" -ErrorAction SilentlyContinue
if (-not $appObj) {
    Write-Host "Creating new app registration for '$displayName'..."

    try {
        $appObj = New-MgApplication -DisplayName $displayName `
            -IdentifierUris @($entityId) `
            -Web @{ RedirectUris = @($replyUrl) }
    }
    catch {
        Write-Error "Failed to create App Registration. Ensure the identifierUris uses a verified domain."
        Write-Error $_
        exit 1
    }

    Write-Host "Created App Registration (AppId = $($appObj.AppId))"
}
else {
    Write-Host "Found existing app registration '$displayName' (AppId = $($appObj.AppId))"
}

# Validate app creation success
if (-not $appObj) {
    Write-Error "App registration object is null. Exiting."
    exit 1
}

$appObjectId = $appObj.Id
$appId = $appObj.AppId

############################################
# 4) Create or get Service Principal
############################################
$spObj = Get-MgServicePrincipal -Filter "appId eq '$appId'" -ErrorAction SilentlyContinue
if (-not $spObj) {
    Write-Host "Creating Service Principal..."
    try {
        $spObj = New-MgServicePrincipal -AppId $appId
        Write-Host "Created Service Principal (Id = $($spObj.Id))"
    }
    catch {
        Write-Error "Failed to create Service Principal."
        Write-Error $_
        exit 1
    }
}
else {
    Write-Host "Found existing Service Principal (Id = $($spObj.Id))"
}

# Validate SP creation success
if (-not $spObj) {
    Write-Error "Service Principal object is null. Exiting."
    exit 1
}

$spObjectId = $spObj.Id

############################################
# 5) Configure Service Principal for SAML SSO
############################################
try {
    Update-MgServicePrincipal -ServicePrincipalId $spObjectId -BodyParameter @{
        preferredSingleSignOnMode = "saml"
        loginUrl                  = $signOnUrl
        samlSingleSignOnSettings  = @{ relayState = $relayState }
    }
    Write-Host "Configured Service Principal for SAML SSO."
}
catch {
    Write-Warning "Failed to configure Service Principal for SAML SSO."
    Write-Warning $_
}

############################################
# 6) Update samlMetadataUrl on App Registration
############################################
try {
    Update-MgApplication -ApplicationId $appObjectId -BodyParameter @{
        samlMetadataUrl = $identityUrl
    }
    Write-Host "Set samlMetadataUrl on App Registration."
}
catch {
    Write-Warning "Failed to set samlMetadataUrl."
    Write-Warning $_
}

############################################
# 7) Issue signing certificate
############################################
try {
    $certResp = Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$spObjectId/addTokenSigningCertificate" `
        -Body (@{
            displayName = "CN=$displayName SAML Signing"
            endDateTime = (Get-Date).AddYears(2).ToString("o")
        } | ConvertTo-Json)

    Write-Host "Certificate thumbprint: $($certResp.thumbprint)"
}
catch {
    Write-Warning "Failed to issue signing certificate."
    Write-Warning $_
}

############################################
# 8) Output Federation Metadata URL
############################################
$federationMetadataUrl = "https://login.microsoftonline.com/$appId/federationmetadata/2007-06/federationmetadata.xml?appid=$appId"
Write-Host "`n✅ SAML app '$displayName' is ready!"
Write-Host "Federation Metadata URL:"
Write-Host "  $federationMetadataUrl"
