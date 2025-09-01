# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Group.ReadWrite.All"

# Define group properties
$groupName = "DynamicGroupps"
$groupDescription = "This group contains all HR department users"
$membershipRule = 'user.department -eq "HR"' 
$membershipRule += ' -and user.city -eq "Haryana"' 
Write-Host $membershipRule


# Create the dynamic group with required parameters
$groupParams = @{
    DisplayName                    = $groupName
    Description                    = $groupDescription
    MailEnabled                     = $false
    SecurityEnabled                 = $true
    MailNickname                    = "DynamicGroupps"
    GroupTypes                      = @("DynamicMembership")
    MembershipRule                  = $membershipRule
    MembershipRuleProcessingState   = "On"
}

# Create the dynamic group with required parameters
New-MgGroup @groupParams 


Update-MgGroup -GroupId "f6427b0a-7410-4952-a285-82ef876b8cff" -MembershipRuleProcessingState "On"