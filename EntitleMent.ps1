Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All","RoleManagement.ReadWrite.Directory"

Import-Module Microsoft.Graph.Identity.Governance
#$catalog = New-MgEntitlementManagementCatalog -DisplayName 'catalogName'

$params = @{
	catalogId ="5510d6d4-833c-48cd-bccf-2faa511c6c90"
	displayName = "Marketing Campaign"
	description = "Access to resources for the campaign"
}

New-MgEntitlementManagementAccessPackage -BodyParameter $params

