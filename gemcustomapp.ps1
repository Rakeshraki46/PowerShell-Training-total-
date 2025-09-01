<#
.SYNOPSIS
    Creates or updates a SAML application in Entra ID from a template, ensuring the
    Entity ID, Reply URL, and other SAML settings are correctly configured in a single operation.
.DESCRIPTION
    This script instantiates a SAML application from a template, waits for the application and its
    service principal to become available, and then updates all necessary SAML properties
    (Entity ID, Reply URL, Sign-on URL, SAML Metadata URL) in a consolidated and reliable manner.
.NOTES
    Author: Gemini Assistant
    Version: 2.2
    Fixes:
    - Consolidated multiple 'Update-MgApplication' calls into one to prevent settings from being
      overwritten, ensuring the custom Entity ID is applied correctly.
    - Improved logic for domain checking by correcting the Get-MgDomain filter.
    - Updated fallback Entity ID to use 'api://{AppId}' format for better reliability.
    - Adjusted certificate expiry to comply with the maximum 3-year policy by setting it to 3 years minus one day.
#>

# --- Script Configuration ---
# Connect to Microsoft Graph with the necessary permissions.
# Application.ReadWrite.All: To create and manage the application registration.
# Directory.ReadWrite.All: Often required for comprehensive app management and SP creation.
# Policy.ReadWrite.ApplicationConfiguration: To manage app policies like token configuration.
try {
    Connect-MgGraph -Scopes "Application.ReadWrite.All", "Directory.ReadWrite.All", "Policy.ReadWrite.ApplicationConfiguration"
    Write-Host "✅ Successfully connected to Microsoft Graph." -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to connect to Microsoft Graph. Please check permissions and try again." -ForegroundColor Red
    return
}


# --- Application & URL Variables ---
$displayName = "madrid-100134" # Changed back to 100131 as per initial request, adjust if you need 100132
$identityUrl = "https://us-region2-tc-tpdbos1.devgateway.verizon.com/metadata" # Used for samlMetadataUrl
$replyUrl    = "https://us-region-2c-tpdbos1.devgateway.verizon.com/secure_access/services/saml/login-consumer" # Reply URL / ACS
$signOnUrl   = "https://us.region-2c-tpdbos1.devgateway.verizon.com/secure_access/services/saml/login-consumer" # Sign On URL

# --- STEP 1: Find or Create the Application Registration ---
$appObj = Get-MgApplication -Filter "displayName eq '$displayName'" -ErrorAction SilentlyContinue

if (-not $appObj) {
    Write-Host "Creating SAML App '$displayName' from template..."

    # Find the generic SAML application template
    $template = Get-MgApplicationTemplate -Filter "displayName eq 'SAML Toolkit'"
    if (-not $template) { throw "❌ No SAML template found. Cannot proceed." }

    # Instantiate the template
    $instantiateParams = @{ displayName = $displayName }
    $instantiatedApp = New-MgApplicationTemplateInstantiedObject -ApplicationTemplateId $template.Id -BodyParameter $instantiateParams

    # Poll until the new application registration is visible via the Graph API
    Write-Host "Waiting for application registration to become visible..."
    for ($i = 0; $i -lt 12; $i++) {
        $appObj = Get-MgApplication -Filter "appId eq '$($instantiatedApp.Application.AppId)'" -ErrorAction SilentlyContinue
        if ($appObj) {
            Write-Host "✅ Application registration is now visible." -ForegroundColor Green
            break
        }
        Start-Sleep -Seconds 5
    }
    if (-not $appObj) { throw "❌ FATAL: Application registration '$displayName' did not become visible after 60 seconds." }
}
else {
    Write-Host "✅ Found existing App '$displayName' (AppId = $($appObj.AppId))"
}

$appObjectId = $appObj.Id
$appId = $appObj.AppId

# --- STEP 2: Find or Create the Service Principal ---
Write-Host "Checking for Service Principal..."
$spObj = Get-MgServicePrincipal -Filter "appId eq '$appId'" -ErrorAction SilentlyContinue

# If the SP doesn't exist, create it and poll for its availability
if (-not $spObj) {
    Write-Host "Service Principal not found. Creating it..."
    New-MgServicePrincipal -AppId $appId | Out-Null
    Write-Host "Waiting for Service Principal to become visible..."
    for ($i = 0; $i -lt 12; $i++) {
        $spObj = Get-MgServicePrincipal -Filter "appId eq '$appId'" -ErrorAction SilentlyContinue
        if ($spObj) {
            Write-Host "✅ Service Principal is now visible." -ForegroundColor Green
            break
        }
        Start-Sleep -Seconds 5
    }
    if (-not $spObj) { throw "❌ FATAL: Service Principal for '$displayName' did not become visible after 60 seconds." }
}
else {
    Write-Host "✅ Service Principal already exists."
}

$spObjectId = $spObj.Id

# --- STEP 3: Define Entity ID based on Verified Domains ---
$preferredEntityId = "https://us-region2-tc-tpdbos1.devgateway.verizon.com/metadata"
$fallbackEntityId  = "api://$appId" # Recommended fallback format

$entityIdToUse = $null
try {
    $uri = [System.Uri]$preferredEntityId
    $domainToCheck = $uri.Host
    # Corrected Get-MgDomain to retrieve all domains and then filter in PowerShell
    $verifiedDomains = (Get-MgDomain | Where-Object { $_.IsVerified -eq $true })

    # Check if any of the verified domains match the domain from the preferredEntityId
    if ($verifiedDomains.Id -contains $domainToCheck) {
        Write-Host "✅ Domain '$domainToCheck' is verified. Using preferred Entity ID." -ForegroundColor Green
        $entityIdToUse = $preferredEntityId
    }
    else {
        # If the preferred domain is not verified, we will fall back to a reliable Entity ID
        Write-Warning "⚠ Domain '$domainToCheck' is not verified. Using fallback Entity ID ('$fallbackEntityId'). Please verify the domain in Entra ID if you intend to use '$preferredEntityId'."
        $entityIdToUse = $fallbackEntityId
    }
}
catch {
    Write-Warning "⚠ Could not parse preferred Entity ID or get verified domains. Using fallback Entity ID ('$fallbackEntityId'). Error: $($_.Exception.Message)"
    $entityIdToUse = $fallbackEntityId
}


# --- STEP 4: CONSOLIDATE ALL APPLICATION UPDATES INTO ONE CALL ---
Write-Host "Preparing consolidated update for the application object..."
$appUpdateParams = @{
    # This is the correct property for the SAML Entity ID
    IdentifierUris = @($entityIdToUse);

    # This sets the Reply URL (Assertion Consumer Service URL)
    Web = @{
        RedirectUris = @($replyUrl)
    };

    # This sets the metadata URL on the app registration
    SamlMetadataUrl = $identityUrl;
}

try {
    Update-MgApplication -ApplicationId $appObjectId -BodyParameter $appUpdateParams
    Write-Host "✅ Successfully updated Application with Entity ID, Reply URL, and Metadata URL in a single call." -ForegroundColor Green
}
catch {
    Write-Host "❌ FAILED to update the application object. Error: $($_.Exception.Message)" -ForegroundColor Red
    return
}


# --- STEP 5: Configure the Service Principal ---
Write-Host "Configuring Service Principal for SAML SSO..."
$spUpdateParams = @{
    PreferredSingleSignOnMode = "saml"
    LoginUrl                  = $signOnUrl
}

try {
    Update-MgServicePrincipal -ServicePrincipalId $spObjectId -BodyParameter $spUpdateParams
    Write-Host "✅ Configured Service Principal for SAML SSO."
}
catch {
    Write-Host "❌ FAILED to update the service principal. Error: $($_.Exception.Message)" -ForegroundColor Red
}

# --- STEP 6: Add a new Token Signing Certificate ---
Write-Host "Adding a new SAML token-signing certificate..."
try {
    $certParams = @{
        DisplayName = "CN=$displayName SAML Signing"
        # FIX APPLIED HERE: Set expiry for 3 years minus one day to satisfy the "not greater than 3 years" rule.
        EndDateTime = (Get-Date).AddYears(3).AddDays(-1).ToString("o")
    }
    Add-MgServicePrincipalTokenSigningCertificate -ServicePrincipalId $spObjectId -BodyParameter $certParams | Out-Null
    Write-Host "✅ New certificate added."
}
catch {
    Write-Warning "⚠ Could not add a new certificate. This may be because one was already added by the template or due to an API error. Error: $($_.Exception.Message)"
}


# --- Final Output ---
$federationMetadataUrl = "https://login.microsoftonline.com/$((Get-MgContext).TenantId)/federationmetadata/2007-06/federationmetadata.xml?appid=$appId"

Write-Host "`n---------- SAML Configuration Complete ----------" -ForegroundColor Cyan
Write-Host "Display Name:            $displayName"
Write-Host "Application (Client) ID: $appId"
Write-Host "Entity ID Applied:       $entityIdToUse"
Write-Host "Reply URL (ACS) Applied: $replyUrl"
Write-Host "Federation Metadata URL: $federationMetadataUrl"
Write-Host "-------------------------------------------------" -ForegroundColor Cyan