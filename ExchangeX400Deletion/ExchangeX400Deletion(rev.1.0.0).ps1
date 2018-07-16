#=========================================================================
#         FILE: ExchangeX400Deletion(rev.1.0.0).ps1
#
#        USAGE: run from powershell ISE. Add Exchange cmdlets with article - 
#               https://blogs.technet.microsoft.com/samdrey/2017/12/17/how-to-load-exchange-management-shell-into-powershell-ise-2/
#
#  DESCRIPTION: delete all X400 email aliasses from all users
#
#        NOTES: 
#       AUTHOR: E.S.Vasilyev - bq@bissquit.com; e.s.vasilyev@mail.ru
#      VERSION: 1.0.0
#      CREATED: 01.02.2018
#=========================================================================

$LogFile = "C:\ExchangeX400Deletion(rev.1.0.0).log"

#header
"Script ExchangeX400Deletion starting work" > "$LogFile"
" " >> "$LogFile"

#gel all mailboxes
$AllMailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox

#measure mailboxes
$AllMailboxesCount = ( $AllMailboxes | Measure-Object ).Count
"Total mailboxes count: " + $AllMailboxesCount >> "$LogFile"

$AllMailboxes | foreach { 

    "User account:     " + $_.Identity >> "$LogFile"

    #save all current addresses
    $AllAliases = $_.EmailAddresses
    "Before changing:  " + $AllAliases  >> "$LogFile"

    #save all addresses except X400
    $AllAliasesExceptX400 = $_.EmailAddresses | Where-Object { $_ -notlike "X400*" }
    "After changing:   " + $AllAliasesExceptX400 >> "$LogFile"

    #apply new addresses
    Set-Mailbox -Identity $_.Identity -EmailAddresses $AllAliasesExceptX400

    " " >> "$LogFile"

}
