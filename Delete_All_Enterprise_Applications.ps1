# List of AppIds to keep (Microsoft Graph only)
$KeepAppIds = @(
    '00000003-0000-0000-c000-000000000000', # Microsoft Graph
    '0bf30f3b-4a52-48df-9a82-234910c4a086' # Microsoft Graph Change Tracking
)

# Get all Service Principals except those to keep
$ToDelete = Get-MgServicePrincipal -All | Where-Object {
    $KeepAppIds -notcontains $_.AppId
}

foreach ($sp in $ToDelete) {
    try {
        Write-Host "Deleting $($sp.DisplayName) ($($sp.Id)) ..."
        Remove-MgServicePrincipal -ServicePrincipalId $sp.Id -ErrorAction Stop
    } catch {
        Write-Host "Could not delete $($sp.DisplayName): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
