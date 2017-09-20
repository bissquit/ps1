$VMSwitchName = 'External' #Name for the new VMSwitch
$VMVlanId = 10 #vlan id for virtual machine
$HostVlanId = 10 #vlan id for host
$NetworkPrefix = "192.168.*" #prefix for network settings
$NicTeamName = "NicTeam" #name of nic team

Clear-Host
Write-Host 'This script reconfigure network connection.' -foregroundcolor DarkGreen

$Continue = Read-Host -Prompt 'Do you want to start? (type Y to start)'
if ($Continue -eq 'Y') {
    Write-Host 'Starting...' -foregroundcolor DarkGreen

    #remove old swithes
    Write-Host 'Disconnect all VMs from existing VMSwitch(es)' -foregroundcolor DarkGreen
    Get-VM | Get-VMNetworkAdapter | Disconnect-VMNetworkAdapter
    Write-Host 'Delete all VMSwitches' -foregroundcolor DarkGreen
    Get-VMSwitch | Remove-VMSwitch -Force

    #Saving network settings
    Write-Host 'Save network settings' -foregroundcolor DarkGreen
    Write-Host 'Save ip-address' -foregroundcolor DarkGreen
    $IpAddress = ( Get-NetIPAddress | Where-Object IPAddress -Like $NetworkPrefix | Select-Object -First 1 ).IPAddress
    Write-Host 'Save prefix length' -foregroundcolor DarkGreen
    $PrefixLength = ( Get-NetIPAddress | Where-Object IPAddress -Like $NetworkPrefix | Select-Object -First 1 ).Prefixlength
    Write-Host 'Save default gateway' -foregroundcolor DarkGreen
    $DefaultGateway = ( Get-WmiObject -Class Win32_IP4RouteTable | where { $_.destination -eq '0.0.0.0' -and $_.mask -eq '0.0.0.0' } | Sort-Object metric1 | select -First 1 nexthop, metric1, interfaceindex ).nexthop
    Write-Host 'Save DNS servers from all ipv4 adaptars' -foregroundcolor DarkGreen
    $DnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object –ExpandProperty ServerAddresses -Unique
    
    #create nic team
    Write-Host 'Create nic teaming from all physical adapters' -foregroundcolor DarkGreen
    New-NetLbfoTeam -Name $NicTeamName -TeamingMode SwitchIndependent -LoadBalancingAlgorithm HyperVPort -TeamMembers ( Get-NetAdapter -Physical ).Name -Confirm:$False

    #create new vmswitch
    Write-Host 'Create new VMSwitch with external type' -foregroundcolor DarkGreen
    New-VMSwitch -Name $VMSwitchName -NetAdapterName $NicTeamName -AllowManagementOS $true -Confirm:$False

    #restore old network settings
    Write-Host 'Configure network settings' -foregroundcolor DarkGreen
    New-NetIPAddress -InterfaceAlias "vEthernet (External)" -IPAddress $IpAddress -PrefixLength $PrefixLength -DefaultGateway $DefaultGateway
    Set-DnsClientServerAddress -InterfaceAlias "vEthernet (External)" -ServerAddresses $DnsServers

    #Connect all VMs to new VMSwitch
    Write-Host 'Connect all VMs to new VMSwitch' -foregroundcolor DarkGreen
    Get-VM | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -VMSwitch ( Get-VMSwitch | Select-Object -First 1 )

    #configure vlan for all VMs
    Write-Host 'Configure vlan for all VMs' -foregroundcolor DarkGreen
    Get-VM | Get-VMNetworkAdapter | Set-VMNetworkAdapterVlan -VlanId $VMVlanId -Access

    #configuring vlan for VMSwitch
    Write-Host 'Configuring vlan for VMSwitch (for host OS)' -foregroundcolor DarkGreen
    Set-VMNetworkAdapterVlan -ManagementOS -Access -VlanId $HostVlanId
}

Write-Host 'Script has finished work' -foregroundcolor DarkGreen