$VMSwitchName = 'External' #Name for the new VMSwitch
$VMVlanId = 10 #vlan id for virtual machine
$HostVlanId = 10 #vlan id for host
$NetworkPrefix = "172.16.*" #prefix for network settings
$NicTeamName = "NicTeam" #name of nic team
$HyperVInstalled = Get-WindowsFeature | Where-Object {$_.Name -eq 'Hyper-V' -and $_.'InstallState' -like 'Installed'}
$IpAddressesCount = ( Get-NetIPAddress | Where-Object IPAddress -Like $NetworkPrefix | Measure-Object ).Count

Clear-Host
Write-Host 'This script reconfigure network connection.' -foregroundcolor Yellow

if ( $IpAddressesCount -gt 1 ) {

    Write-Host 'You server have more than 1 network adresses from single network! This script has optimized for single address server configuration' -foregroundcolor Red
    Write-Host 'Exiting...' -foregroundcolor Red
    exit

} else {

    #Saving network settings
    Write-Host "You current network settings will be saved:" -foregroundcolor Yellow
    $IpAddress = ( Get-NetIPAddress | Where-Object IPAddress -Like $NetworkPrefix | Select-Object -First 1 ).IPAddress
    Write-Host "Ip address: $IpAddress" -foregroundcolor Green
    $PrefixLength = ( Get-NetIPAddress | Where-Object IPAddress -Like $NetworkPrefix | Select-Object -First 1 ).Prefixlength
    Write-Host "Prefix length: $PrefixLength" -foregroundcolor Green
    $DefaultGateway = ( Get-WmiObject -Class Win32_IP4RouteTable | where { $_.destination -eq '0.0.0.0' -and $_.mask -eq '0.0.0.0' } | Sort-Object metric1 | select -First 1 nexthop, metric1, interfaceindex ).nexthop
    Write-Host "Default gateway: $DefaultGateway" -foregroundcolor Green
    $DnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object –ExpandProperty ServerAddresses -Unique
    Write-Host "DNS servers: $DnsServers" -foregroundcolor Green

    #remove current network settings
    #Write-Host "Remove settings" -foregroundcolor Yellow
    #Get-NetIPAddress | Where-Object { $_.IPAddress -like $NetworkPrefix } | Remove-NetIPAddress -Confirm:$False

}

function CreateNicTeam {
    
    param ( $TeamingName )

    #create nic team
    Write-Host 'Create nic teaming from all physical adapters' -foregroundcolor Yellow
    New-NetLbfoTeam -Name $TeamingName -TeamingMode SwitchIndependent -LoadBalancingAlgorithm IPAddresses -TeamMembers ( Get-NetAdapter -Physical ).Name -Confirm:$False

}

function RestoreNetworkSettings {

    param ( $AdapterName )

    #restore old network settings
    Write-Host 'Configure network settings' -foregroundcolor Yellow
    New-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $IpAddress -PrefixLength $PrefixLength -DefaultGateway $DefaultGateway
    Set-DnsClientServerAddress -InterfaceAlias $AdapterName -ServerAddresses $DnsServers

}

#        CreateNicTeam -TeamingName $NicTeamName
#        RestoreNetworkSettings -AdapterName $NicTeamName



$Continue = Read-Host -Prompt 'Do you want to start? (type Y to start)'
if ( $Continue -eq 'Y' ) {

    Write-Host 'Starting...' -foregroundcolor Yellow

    if ($HyperVInstalled -ne $null) {

        Write-Host 'The server has Hyper-V role' -foregroundcolor Yellow
        
        #disconnect virtual network adapters
        Write-Host 'Disconnect all VMs from existing VMSwitch(es)' -foregroundcolor Yellow
        Get-VM | Get-VMNetworkAdapter | Disconnect-VMNetworkAdapter

        #remove old swithes
        Write-Host 'Delete all VMSwitches' -foregroundcolor Yellow
        Get-VMSwitch | Remove-VMSwitch -Force
        
        #create nic team    
        CreateNicTeam -TeamingName $NicTeamName
    
        #create new vmswitch
        Write-Host 'Create new VMSwitch with external type' -foregroundcolor Yellow
        New-VMSwitch -Name $VMSwitchName -NetAdapterName $NicTeamName -AllowManagementOS $true -Confirm:$False

        #restore old network settings
        RestoreNetworkSettings -AdapterName "vEthernet (External)"
    
        #Connect all VMs to new VMSwitch
        Write-Host 'Connect all VMs to new VMSwitch' -foregroundcolor Yellow
        Get-VM | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -VMSwitch ( Get-VMSwitch | Select-Object -First 1 )
    
        #configure vlan for all VMs
        Write-Host 'Configure vlan for all VMs' -foregroundcolor Yellow
        Get-VM | Get-VMNetworkAdapter | Set-VMNetworkAdapterVlan -VlanId $VMVlanId -Access
    
        #configuring vlan for VMSwitch
        Write-Host 'Configuring vlan for VMSwitch (for host OS)' -foregroundcolor Yellow
        Set-VMNetworkAdapterVlan -ManagementOS -Access -VlanId $HostVlanId

    } else {
        
        Write-Host 'The server has no Hyper-V role' -foregroundcolor Yellow

        #create nic team 
        CreateNicTeam -TeamingName $NicTeamName

        #restore old network settings
        RestoreNetworkSettings -AdapterName $NicTeamName

    }
    
}

Write-Host 'Script has finished work' -foregroundcolor Green