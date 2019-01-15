# https://psjira.readthedocs.io/en/latest/getting_started.html
#
# On new host (powershell v5.0) run:
# >Install-Module PSJira
#
# On new host (powershell before v5.0) run:
# >Install-Module -Name PowerShellGet -Force
# ...and then:
# >Install-Module PSJira
#
# Read more at https://psjira.readthedocs.io/en/latest/
param (

    [string]$Username = "jirabot",
    [string]$Userpass = "password",
    [string]$Server = "https://jira.domain.tld",
    [string]$Project = "IM",
    [string]$IssueType = "Task",
    [string]$Summary = "Test issue from PowerShell $(Get-Random)",
    [string]$Description = "This is a sample issue created by $env:USERNAME on $env:COMPUTERNAME. Tratata",
    [string]$originalEstimate = "1h",
    [string]$Assignee = "jirabot@domain.tld"

)

Set-JiraConfigServer -Server $Server

# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/get-credential?view=powershell-6
$Password = ConvertTo-SecureString -String $Userpass `
                                   -AsPlainText `
                                   -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential `
                   -ArgumentList $Username, $Password

New-JiraSession -Credential $Cred

# define task parameters to create a task
$NewIssueParameters = @{
    Project = $Project
    IssueType = $IssueType
    Summary = $Summary
    Description = $Description

    Fields = @{

        "Time Tracking" = @{
            originalEstimate = $originalEstimate
            remainingEstimate = ""
            originalEstimateSeconds = ""
            remainingEstimateSeconds = ""
        }

        "Priority" = @{
            self = "$Server/rest/api/2/priority/2"
            iconUrl = "$Server/images/icons/priorities/high.svg"
            name = "High"
            id = "2"
        }
    }
}
$OutputNewJiraIssue = New-JiraIssue @NewIssueParameters

# define task parameters to update a task
$EditNewIssueParameters = @{
    Assignee = $Assignee
}
Set-JiraIssue $OutputNewJiraIssue.ID @EditNewIssueParameters

# close session
Get-JiraSession | Remove-JiraSession

