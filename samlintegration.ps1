Connect-MgGraph -Scopes "Application.ReadWrite.All","Directory.ReadWrite.All"

Import-Module Microsoft.Graph.Applications
#Select-MgProfile -Name "beta"

#Get application template ID for specific gallery app. Note that this needs to be done per SaaS App. So, you want to get this dynamically at run time in case you are creating multiple apps based on a list or something similar

$appTemplate = Get-MgApplicationTemplate -Filter "DisplayName eq 'Atlassian Cloud'"#jira

$applicationTemplateId=$appTemplate.Id
Write-Host "Application Template ID: " $applicationTemplateId

$params = @{
    DisplayName = "Atlassian Cloud gallery App PS"
}
Invoke-MgInstantiateApplicationTemplate -ApplicationTemplateId $applicationTemplateId -BodyParameter $params

Write-Host "Application and Service Principal object created, Waiting for a minute before updating them "

Start-Sleep -Seconds 60

#Get SPN Details
$createSPN = Get-MgServicePrincipal -Filter "DisplayName eq 'Atlassian Cloud gallery App PS'"
$servicePrincipalId = $createSPN.Id

#Get App registration Details
$createdAppReg = Get-MgApplication -Filter "DisplayName eq 'Atlassian Cloud gallery App PS'"
$applicationId = $createdAppReg.Id


#Update Application Object first, you can choose whatever parameters you want to update
$params = @{
    Web = @{
        RedirectUris = @(
            "https://id.atlassian.com/finishlogin/saml"
        )
        logoutUrl = "https://aws.itsecguy.biz/saml/logoutX" #This parameter is only available in Application Object and gets updated to SP Object as Logout Url 
    }
    IdentifierUris = @(
        "https://id.atlassian.itsecguy.biz/saml" # This parameter is is only available in Application Object and gets updated on SP object as Entity ID/Identifier. identifierUris property must use a verified domain of the organization or its subdomain.
    )   
}
Update-MgApplication -ApplicationId $applicationId -BodyParameter $params

#Now let's update the Service Principal Object

# Update SamlSingleSignOnSettings such as Relay state
$params = @{
    PreferredSingleSignOnMode = "saml" #The supported values for this parameter are password, saml, notSupported, and oidc.
}
Update-MgServicePrincipal -ServicePrincipalId $servicePrincipalId -BodyParameter $params

#Add a token signing certifcate to the Service Principal
Add-MgServicePrincipalTokenSigningCertificate -ServicePrincipalId $servicePrincipalId
Start-Sleep -Seconds 5

Write-Host "Token signing certificate is added to the Service Principal "

$params = @{
    NotificationEmailAddresses = "testemail@xyz.com" #Updates the notification email where cert expriry notifications are sent to
    LoginUrl = "https://aws.itsecguy.biz/saml/login" #Updates Sign on URL parameter on enterprise apps
    SamlSingleSignOnSettings = $samlssosettingsParams
}
Update-MgServicePrincipal -ServicePrincipalId $servicePrincipalId -BodyParameter $params

Write-Host "Service Principal SSO settings updated"