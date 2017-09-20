#set up a collection of remote servers
$collection = 

"server1",
"server2"

function GetCurrentDnsServers {
    
    param ( $Server )

    Invoke-Command -ComputerName $Server { ( Get-DnsClientServerAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4 ).ServerAddresses }

}

cls
Write-Host ( "Script starting works" ) -foreground "Red"

foreach ( $item in $collection ) {

    Write-Host ( ( Invoke-Command -ComputerName $item { $env:computername } ), "current DNS servers:" ) -foreground "Green"
    GetCurrentDnsServers -Server $item
    Invoke-Command -ComputerName $item {  Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ( "192.168.1.29", "192.168.1.17" ) }
    Write-Host ( "New DNS servers:" )
    GetCurrentDnsServers -Server $item

}