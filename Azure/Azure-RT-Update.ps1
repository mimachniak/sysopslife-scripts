
## 172.16.37.5 / 10.234.20.4
## 10.224.17.5 / 10.224.17.4
$rg_name = "T-Platform-AZNEu-NET-RG01"
$rt_name = "T-PlatformVMX-AZNEu-RT01"
$old_next_hope = "172.16.37.5"
$new_next_hope = "10.234.20.4"

$rt = Get-AzRouteTable -ResourceGroupName $rg_name -Name $rt_name

$rt_settings = Get-AzRouteTable -ResourceGroupName $rg_name -Name $rt_name | Get-AzRouteConfig | Where-Object -Property NextHopIpAddress -Like $old_next_hope
foreach ($rt_set in $rt_settings)
{
    Set-AzRouteConfig -RouteTable $rt -Name $rt_set.name -AddressPrefix $rt_set.AddressPrefix -NextHopIpAddress $new_next_hope -NextHopType VirtualAppliance | Set-AzRoutetable 

}