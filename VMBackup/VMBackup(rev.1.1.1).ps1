#=========================================================================
#         FILE: VMBackup(rev.1.1.1).ps1
#
#        USAGE: run from task scheduler
#               In Action pane type (on scheduler task): -file "C:\Users\dpmservice\VMBackup(rev.1.0.0).ps1"
#               Change $VMName and other variables!
#
#  DESCRIPTION: backup any virtual machine and store in remote folder
#
#        NOTES:
#       AUTHOR: E.S.Vasilyev - bq@bissquit.com; e.s.vasilyev@mail.ru
#      VERSION: 1.1.1
#      CREATED: 05.02.2018
#=========================================================================

$VMName = "GATEWAY"
$BackupName = "$VMName-" + ( Get-Date ).DayOfWeek + "-Backup"
#temporary folder
$VMSnapshotPath = "D:\"
#backup storage path
$VMRemoteSnapshotPath = "\\remoteserver\Data"
#log file path
$LogFilePath = "D:\Data\log.log"

function Timestamp {

    "[" + ( Get-Date -Format s) + "] "

}

function GetFolderSize {

    param ( $FolderName )

    $colItems = ( Get-ChildItem $BackupName -Recurse | Measure-Object -Property Length -Sum )
    "{0:N2}" -f ( $colItems.Sum / 1MB ) + " MB"

}

cls
Set-Location $VMSnapshotPath
#( TimeStamp ) + "Work directory - $VMSnapshotPath"

#create snapshot
( TimeStamp ) + "Snapshot creation..." | Out-File "$LogFilePath" -Append
Get-VM -Name $VMName | Checkpoint-VM
( TimeStamp ) + "Snapshot was created" | Out-File "$LogFilePath" -Append

#get vm snapshot GUID
$VMSnapshotID = ( Get-VM -Name "$VMName" | Get-VMSnapshot | Where-Object { ( $_.CreationTime ).Date -ge ( Get-Date ).Date } | Select-Object -first 1 ).Id

#export snapshot
( TimeStamp ) + "Export snapshot to $VMSnapshotPath..." | Out-File "$LogFilePath" -Append
Get-VMSnapshot -Id "$VMSnapshotID" | Export-VMSnapshot -Path "$VMSnapshotPath"
( TimeStamp ) + "Snapshot export has finished" | Out-File "$LogFilePath" -Append

#rename snapshot with current day of week in name
Rename-Item -NewName $BackupName -Path $VMName

#remove vm snapshot
( TimeStamp ) + "Snapshot removing..." | Out-File "$LogFilePath" -Append
Get-VMSnapshot -Id "$VMSnapshotID" | Remove-VMSnapshot
( TimeStamp ) + "Snapshot removing has finished" | Out-File "$LogFilePath" -Append

Set-Location $VMRemoteSnapshotPath
#remove old backup
( TimeStamp ) + "Checking old backup..." | Out-File "$LogFilePath" -Append
if ( ( Test-Path $BackupName ) -eq "True" ) {

    ( TimeStamp ) + "Old backup size: " + ( GetFolderSize -FolderName $BackupName ) | Out-File "$LogFilePath" -Append
    Remove-Item -Path $BackupName -Force -Recurse
    ( TimeStamp ) + "$BackupName was removed from $VMRemoteSnapshotPath" | Out-File "$LogFilePath" -Append

} else {

    ( TimeStamp ) + "Old backup was not found" | Out-File "$LogFilePath" -Append

}

#backup transfer
( TimeStamp ) + "Transferring data from $VMSnapshotPath to $VMRemoteSnapshotPath..." | Out-File "$LogFilePath" -Append
Move-Item -Path "$VMSnapshotPath\$BackupName" -Destination "$VMRemoteSnapshotPath\$BackupName"
( TimeStamp ) + "Backup transferring has finished" | Out-File "$LogFilePath" -Append

( TimeStamp ) + "Transferred: " + ( GetFolderSize -FolderName $BackupName ) | Out-File "$LogFilePath" -Append

( TimeStamp ) + "Script has finished work" | Out-File "$LogFilePath" -Append
