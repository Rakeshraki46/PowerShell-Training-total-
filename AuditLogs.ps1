. "$PSScriptRoot\Config.ps1"
import-module microsoft.graph.reports
Connect-MgGraph -Scopes 'auditlog.read.all' 
#Get-MgAuditLogDirectoryAudit | Select-Object activityDateTime, Id, Category, Result 
Get-MgAuditLogDirectoryAudit -Filter "activityDateTime ge 2024-01-28T10:00:00Z"
