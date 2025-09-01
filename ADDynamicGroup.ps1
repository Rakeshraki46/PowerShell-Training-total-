# Import Active Directory module
Import-Module ActiveDirectory

# Path to CSV
$csvPath = "C:\Users\Administrator\Desktop\powershell\DynamicGroup.csv"
$users = Import-Csv -Path $csvPath

# OUs
$userOU = "OU=User,DC=meg,DC=com"
$groupOU = "OU=Group,DC=meg,DC=com"

# Ensure OUs exist
if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$userOU)")) {
    New-ADOrganizationalUnit -Name "User" -Path "DC=meg,DC=com"
}
if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$groupOU)")) {
    New-ADOrganizationalUnit -Name "Group" -Path "DC=meg,DC=com"
}

# Track valid usernames from CSV
$csvUsernames = $users.UserName

# Loop through each user in CSV
foreach ($user in $users) {
    $userName = $user.UserName
    $displayName = $user.DisplayName
    $department = $user.Department
    $staticGroups = $user.StaticGroup -split "," | ForEach-Object { $_.Trim() }
    $dynamicGroup = $user.DynamicGroup
    $groupType = $user.GroupType
    $userPrincipalName = "$userName@meg.com"

    # Get or create user
    $existingUser = Get-ADUser -Filter "SamAccountName -eq '$userName'" -Properties Department, MemberOf -ErrorAction SilentlyContinue

    if (-not $existingUser) {
        $password = ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force
        try {
            New-ADUser `
                -SamAccountName $userName `
                -UserPrincipalName $userPrincipalName `
                -Name $displayName `
                -DisplayName $displayName `
                -Department $department `
                -Path $userOU `
                -AccountPassword $password `
                -Enabled $true
            Write-Host "Created user: $userName"
        } catch {
            Write-Host "Failed to create user $userName - $($_.Exception.Message)"
        }
    } else {
        # Update department if changed
        if ($existingUser.Department -ne $department) {
            Set-ADUser -Identity $userName -Department $department
            Write-Host "Updated department for ${userName}: ${department}"
        }

        # Remove from old static groups not in current list
        $existingGroups = $existingUser.MemberOf | ForEach-Object {
            (Get-ADGroup $_).Name
        } | Where-Object {
            $_ -ne $dynamicGroup
        }

        foreach ($grp in $existingGroups) {
            if ($staticGroups -notcontains $grp) {
                try {
                    Remove-ADGroupMember -Identity $grp -Members $userName -Confirm:$false
                    Write-Host "Removed $userName from old static group $grp"
                } catch {
                    Write-Host "Could not remove $userName from $grp - $($_.Exception.Message)"
                }
            }
        }
    }

    # Ensure and assign static groups
    foreach ($group in $staticGroups) {
        if ($group) {
            if (-not (Get-ADGroup -Filter { Name -eq $group } -ErrorAction SilentlyContinue)) {
                $groupTypeParam = if ($groupType -eq "Security") { "Security" } else { "Distribution" }
                New-ADGroup `
                    -Name $group `
                    -SamAccountName $group `
                    -GroupCategory $groupTypeParam `
                    -GroupScope Global `
                    -Path $groupOU
                Write-Host "Created static group: $group"
            }

            try {
                Add-ADGroupMember -Identity $group -Members $userName -ErrorAction Stop
                Write-Host "Ensured $userName is in static group $group"
            } catch {
                Write-Host "Skipped (already exists or error): $userName in $group"
            }
        }
    }

    # Ensure dynamic group exists
    if ($dynamicGroup) {
        if (-not (Get-ADGroup -Filter { Name -eq $dynamicGroup } -ErrorAction SilentlyContinue)) {
            $groupTypeParam = if ($groupType -eq "Security") { "Security" } else { "Distribution" }
            New-ADGroup `
                -Name $dynamicGroup `
                -SamAccountName $dynamicGroup `
                -GroupCategory $groupTypeParam `
                -GroupScope Global `
                -Path $groupOU
            Write-Host "Created dynamic group: $dynamicGroup"
        }

        # Remove user from all other dynamic groups in CSV
        $allDynamicGroups = $users | Select-Object -ExpandProperty DynamicGroup -Unique
        foreach ($grpName in $allDynamicGroups) {
            if ($grpName -and $grpName -ne $dynamicGroup) {
                try {
                    Remove-ADGroupMember -Identity $grpName -Members $userName -Confirm:$false -ErrorAction SilentlyContinue
                } catch {}
            }
        }

        try {
            Add-ADGroupMember -Identity $dynamicGroup -Members $userName -ErrorAction SilentlyContinue
            Write-Host "Ensured $userName is in dynamic group $dynamicGroup"
        } catch {
            Write-Host "Failed to add $userName to $dynamicGroup - $($_.Exception.Message)"
        }
    }
}

# Cleanup: remove users from all groups if they are missing from CSV
$allGroups = Get-ADGroup -SearchBase $groupOU -Filter * | Select-Object -ExpandProperty Name
foreach ($group in $allGroups) {
    $members = Get-ADGroupMember -Identity $group -Recursive | Where-Object { $_.objectClass -eq 'user' }
    foreach ($member in $members) {
        if ($csvUsernames -notcontains $member.SamAccountName) {
            try {
                Remove-ADGroupMember -Identity $group -Members $member -Confirm:$false
                Write-Host "Removed $($member.SamAccountName) from $group (not in CSV)"
            } catch {
                Write-Host "Failed to remove $($member.SamAccountName) from $group - $($_.Exception.Message)"
            }
        }
    }
}

Write-Host "`n✅ All users and groups are now fully synchronized."
