$VMName = "GATEWAY"
$BackupName = "$VMName-" + ( Get-Date ).DayOfWeek + "-Backup"
$VMSnapshotPath = "D:\Data"

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
( TimeStamp ) + "Work directory - $VMSnapshotPath"

#remove old backup
( TimeStamp ) + "Check old backup..."
if ( ( Test-Path $BackupName ) -eq "True" ) {

    ( TimeStamp ) + "Old data size: " + ( GetFolderSize -FolderName $BackupName )
    Remove-Item -Path $BackupName -Force -Recurse
    ( TimeStamp ) + "$BackupName was removed"

} else {

    ( TimeStamp ) + "Old backup was not found"

}

#create snapshot
( TimeStamp ) + "Start snapshot creation"
Get-VM -Name $VMName | Checkpoint-VM
( TimeStamp ) + "Snapshot was created"

#get vm snapshot GUID
$VMSnapshotID = ( Get-VM -Name "$VMName" | Get-VMSnapshot | Where-Object { ( $_.CreationTime ).Date -ge ( Get-Date ).Date } | Select-Object -first 1 ).Id

#export snapshot
( TimeStamp ) + "Snapshot export has started..."
Get-VMSnapshot -Id "$VMSnapshotID" | Export-VMSnapshot -Path "$VMSnapshotPath"
( TimeStamp ) + "Snapshot export has finished"

#rename snapshot with current day of week in name
Rename-Item -NewName $BackupName -Path $VMName

( TimeStamp ) + "Transferred: " + ( GetFolderSize -FolderName $BackupName )

#remove vm snapshot
( TimeStamp ) + "Snapshot removing has started..."
Get-VMSnapshot -Id "$VMSnapshotID" | Remove-VMSnapshot
( TimeStamp ) + "Snapshot removing has finished"

( TimeStamp ) + "Script has finished work"