#list of your dns servers
$ServerAddresses = "192.168.1.29","192.168.1.17"
#network interface name. Multiple names are not supported
$InterfaceAlias = "Ethernet"

#setting up a collection of remote servers
$collection = 

"server1",
"server2"

cls
Write-Host ( "Script starting works" ) -foreground "Red"

foreach ( $item in $collection ) {

    Invoke-Command -ComputerName $item -ScriptBlock { 
    
        param( $arg1, $arg2 ) 
        
        Write-Host ( $env:computername, "current DNS servers:" ) -foreground "Green"
        ( Get-DnsClientServerAddress -InterfaceAlias $arg1 -AddressFamily IPv4 ).ServerAddresses
        Set-DnsClientServerAddress -InterfaceAlias "$arg1" -ServerAddresses ( $arg2 )
        Write-Host ( "New DNS servers:" ) -foreground "Green"
        ( Get-DnsClientServerAddress -InterfaceAlias $arg1 -AddressFamily IPv4 ).ServerAddresses
    
    } -ArgumentList ( $InterfaceAlias, $ServerAddresses )

}