Import-Module Microsoft.Graph.Identity.SignIns

Get-MgIdentityConditionalAccessTemplate -ConditionalAccessTemplateId a297dd1a-21fe-4016-99a0-ba43ba64378c -property "name" | Format-List

Connect-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess'

$params = @{
"@odata.type" = "#microsoft.graph.countryNamedLocation"
DisplayName = "Named locations"
CountriesAndRegions = @(
    "US"
    "XK"
)
IncludeunknownCountriesAndRegions = $true
}

New-MgIdentityConditionalAccessNamedLocation -BodyParameter $params | Format-List




######################################################################################################


$params = @{
	displayName = "CAP"
	state = "enabled"
	conditions = @{
		clientAppTypes = @(
	"browser"
)
applications = @{
	includeApplications = @(
	"6ce42e36-1ab0-472f-9c2e-54f9f1850360"
)
}
users = @{
includeGroups = @(
"3fb8780f-5dac-4d29-8796-6cbc16ba6caa"
)
}
locations = @{
includeLocations = @(
"All"
)
excludeLocations = @(
"AllTrusted"
)
}
}
grantControls = @{
operator = "OR"
builtInControls = @(
"mfa" 
)
}
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params | Format-List