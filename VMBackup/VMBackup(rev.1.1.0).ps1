$VMName = "GATEWAY"
$BackupName = "$VMName-" + ( Get-Date ).DayOfWeek + "-Backup"
#temporary folder
$VMSnapshotPath = "D:\"
#backup storage path
$VMRemoteSnapshotPath = "\\scoutreserve01\Data"

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
( TimeStamp ) + "Snapshot creation..."
Get-VM -Name $VMName | Checkpoint-VM
( TimeStamp ) + "Snapshot was created"

#get vm snapshot GUID
$VMSnapshotID = ( Get-VM -Name "$VMName" | Get-VMSnapshot | Where-Object { ( $_.CreationTime ).Date -ge ( Get-Date ).Date } | Select-Object -first 1 ).Id

#export snapshot
( TimeStamp ) + "Export snapshot to $VMSnapshotPath..."
Get-VMSnapshot -Id "$VMSnapshotID" | Export-VMSnapshot -Path "$VMSnapshotPath"
( TimeStamp ) + "Snapshot export has finished"

#rename snapshot with current day of week in name
Rename-Item -NewName $BackupName -Path $VMName

#remove vm snapshot
( TimeStamp ) + "Snapshot removing..."
Get-VMSnapshot -Id "$VMSnapshotID" | Remove-VMSnapshot
( TimeStamp ) + "Snapshot removing has finished"

Set-Location $VMRemoteSnapshotPath
#remove old backup
( TimeStamp ) + "Checking old backup..."
if ( ( Test-Path $BackupName ) -eq "True" ) {

    ( TimeStamp ) + "Old backup size: " + ( GetFolderSize -FolderName $BackupName )
    Remove-Item -Path $BackupName -Force -Recurse
    ( TimeStamp ) + "$BackupName was removed from $VMRemoteSnapshotPath"

} else {

    ( TimeStamp ) + "Old backup was not found"

}

#backup transfer
( TimeStamp ) + "Transferring data from $VMSnapshotPath to $VMRemoteSnapshotPath..."
Move-Item -Path "$VMSnapshotPath\$BackupName" -Destination "$VMRemoteSnapshotPath\$BackupName"
( TimeStamp ) + "Backup transferring has finished"

( TimeStamp ) + "Transferred: " + ( GetFolderSize -FolderName $BackupName )

( TimeStamp ) + "Script has finished work"