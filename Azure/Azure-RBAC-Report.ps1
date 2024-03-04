#Requires –Modules ImportExcel
#Requires –Modules Az

$DateString = (Get-Date).ToString('yyyyMMdd-mmss')
$fileName = 'Euvic-Azure-RBAC'+$DateString+'.xlsx'
$reportFile = 'C:\Temp\'+$fileName
$tenantId = 'tenantID' #In case when your account have access to more than one Azure Tenant

$list_subscriptions = Get-AzSubscription -TenantId $tenantID | Where-Object {$_.State -ne "Disabled"}

$rbac_report = @()

foreach ($sub in $list_subscriptions)
{
    
    Set-AzContext -SubscriptionId $sub.Id
    #Write-Output ("**Subscription: " + $sub.Name + "**")
    $list_role = Get-AzRoleAssignment -IncludeClassicAdministrators
    $sub_quota_id = ($sub.SubscriptionPolicies.QuotaId).Split("_")
    $sub_quota_id = $sub_quota_id[0]
    
    foreach ($role in $list_role) {


        #$role.SignInName
        #$role.RoleDefinitionName
        #$role.ObjectType
<##>
        if ($role.ObjectType -eq "Group") {

            $SignInName = $role.DisplayName

        } elseif ($role.ObjectType -eq "ServicePrincipal") {

            $SignInName = $role.ObjectId
        }
        else {

            $SignInName = $role.SignInName
        }

            $rbac_report_data = New-Object -TypeName pscustomobject
            $rbac_report_data | Add-Member -MemberType NoteProperty -Name 'SubscriptionID' -Value $sub.Id
            $rbac_report_data | Add-Member -MemberType NoteProperty -Name 'SubscriptionName' -Value $sub.Name
            $rbac_report_data | Add-Member -MemberType NoteProperty -Name 'CostSpending' -Value $sub_quota_id
            $rbac_report_data | Add-Member -MemberType NoteProperty -Name 'SignInName' -Value $SignInName
            $rbac_report_data | Add-Member -MemberType NoteProperty -Name 'ObjectId' -Value "$($role.ObjectId)"
            $rbac_report_data | Add-Member -MemberType NoteProperty -Name 'RoleDefinitionName' -Value $role.RoleDefinitionName
            $rbac_report_data | Add-Member -MemberType NoteProperty -Name 'Scope' -Value $role.Scope
            $rbac_report_data | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value $role.ObjectType
            $rbac_report += $rbac_report_data

    }
    
}
$rbac_report | Export-Excel $reportFile -AutoSize -StartRow 1 -TableName RBAC-Accounts -WorksheetName RBAC-Accounts


