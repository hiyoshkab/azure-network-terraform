$ErrorActionPreference = 'Stop'

$azureDnsIp = '168.63.129.16'
$privateLinkZone = 'privatelink.azurewebsites.net'

Install-WindowsFeature -Name DNS -IncludeManagementTools
Set-DnsServerForwarder -IPAddress $azureDnsIp -UseRootHint $false

$existingZone = Get-DnsServerZone -Name $privateLinkZone -ErrorAction SilentlyContinue
if ($null -eq $existingZone) {
    Add-DnsServerConditionalForwarderZone -Name $privateLinkZone -MasterServers $azureDnsIp
}
else {
    Set-DnsServerConditionalForwarderZone -Name $privateLinkZone -MasterServers $azureDnsIp
}