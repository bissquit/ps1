#=========================================================================
#         FILE: LinuxVMCreate(rev.1.0.0).ps1
#
#        USAGE: run script without parameters (default settings) or retype any
#               options like in New-VM comdlet
#
#  DESCRIPTION: create test vm with default parameters in default location 
#               with Microsoft's recommendation for Linux Guests drives.
#               see https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/best-practices-for-running-linux-on-hyper-v
#
#        NOTES: For 2012R2/8.1 hosts with Hyper-V role.
#               If you run script without parameters all settings will be extracted from default hyper-v settings 
#       AUTHOR: E.S.Vasilyev - bq@bissquit.com; e.s.vasilyev@mail.ru
#      VERSION: 1.0.0
#      CREATED: 15.03.2018
#=========================================================================
        
param (

    [string]$Name = "testvm" + (Get-Date -UFormat "%Y%m%d-%H%M%S"),
    [string]$MemoryStartupBytes = 512MB,
    [string]$BootDevice = "CD",
    [string]$Path = (Get-VMHost).VirtualMachinePath,
    [string]$NewVHDPath = $Path + $Name + "\Virtual Hard Disks\" + $Name + "-DISK001.vhdx",
    [string]$NewVHDSizeBytes = 16GB,
    [string]$SwitchName = (Get-VMSwitch -SwitchType External).Name,
    [string]$Generation = 2

)

# create virtual disk location
New-Item -ItemType directory -Path ((Get-VMHost).VirtualMachinePath + $Name + "\Virtual Hard Disks\")

# create vm
New-VM -Name $Name `
       -MemoryStartupBytes $MemoryStartupBytes `
       -BootDevice $BootDevice `
       -Path $Path `
       -NewVHDPath $NewVHDPath `
       -NewVHDSizeBytes $NewVHDSizeBytes `
       -SwitchName $SwitchName `
       -Generation $Generation

Rename-Item -Path $NewVHDPath -NewName ($NewVHDPath + ".tmp")

# create new vhd with different settings
New-VHD -Path $NewVHDPath `
        -SizeBytes $NewVHDSizeBytes

# copy and set acl for a new disk
Get-Acl -Path ($NewVHDPath + ".tmp") | Set-Acl -Path $NewVHDPath

# remove old disk
Remove-Item -Path ($NewVHDPath + ".tmp") -Force
