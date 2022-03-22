<#

.DESCRIPTION

Build and invoke lists of queries for use with Get-GitHubIssues, to help 
reliably search all repositories that are of interest to you.

Relies $ENV:GITHUB_REPOS being set in the environment.

$ENV:GITHUB_REPOS = @('org/repo1',
                      'org2/repo2') -join ' '

#>

<#
.SYNOPSIS

Call this to verify your $ENV:GITHUB_REPOS variable is set correctly for this 
module.

.EXAMPLE

$ENV:GITHUB_REPOS = 'org/repo1 org2/repo2'
Get-AgileRepo

#>
function Get-AgileRepo {
    param(
        [string]$repos
    )
    begin {
        $results = @()
        if(-Not $repos){
            $repos = $ENV:GITHUB_REPOS
        }
        if(-Not $repos) {
            Write-Warning "GITHUB_REPOS environment variable is not set."
        }
        $repo_strings = $repos.split(' ')
    }
    process {
        $repo_strings | ForEach-Object {
            $owner, $repo = $_.split('/')
            $result = [PSCustomObject]@{
                OwnerName = $owner
                RepoName = $repo
            }
            if(-Not($skip -contains $repo)){
                 $results += $result
            }
        }
    }
    end {
        return $results
    }
}
function Get-AgileUser {
    $username = $ENV:GITHUB_USERNAME
    if(-Not $username) {
        Write-Warning "GITHUB_USERNAME environment variable is not set."
    }
    return $username
}


<#

.SYNOPSIS

Get queries to pass to Get-GitHubIssues based on your $ENV:GITHUB_REPOS
environment setting.

.EXAMPLE

$ENV:GITHUB_REPOS = @('org/repo1', 'org2/repo2')
$issues = @()
$queries = Get-AgileQuery -state 'Open'
$queries | ForEach-Object { 
    $query = $_
    $issues += Get-GitHubIssue @query
}
($issues | Measure-Object).Count


#>
function Get-AgileQuery {
    param(
        [string]$repos,
        [string]$assignee,
        [switch]$mine,
        [string]$sort = "updated",
        [string]$state = 'Open',
        [string]$direction = "Descending"
    )
    begin {
        $queries = @()
        $repo_list = Get-AgileRepo -repos $repos
        if($mine) {
            $assignee = $ENV:GITHUB_USERNAME
        }
    }
    process {
        $repo_list | ForEach-Object {
            $owner_name = $_.OwnerName
            $repo = $_.RepoName
            $query = [PSCustomObject]@{
                OwnerName = $owner_name
                RepositoryName = $repo
                State = $state
                Sort = $sort
                Direction = $direction
                Assignee = $assignee
            }
            $queries += $query
        }
    }
    end {
        return $queries
    }
}

<#

.SYNOPSIS

Invoke queries with Get-GitHubIssues, gathering the returned issue objects.
Typically used with Get-AgileQuery.

.EXAMPLE

$ENV:GITHUB_REPOS = @('org/repo1', 'org2/repo2')
$issues = Invoke-AgileQuery -queries (Get-AgileQuery -closed)
($issues | Measure-Object).Count
$issues | Show-MarkdownFromGitHub

.EXAMPLE

To output all team member's assigned issues as Markdown.

$team = @('teammate1', 'teammate2', 'teammate3')
$team | ForEach-Object {
    "## $_ - Issues Assigned"
    Get-AgileQuery -Assignee $_ | Invoke-AgileQuery | Show-MarkdownFromGitHub
}

#>
function Invoke-AgileQuery {
    param(
        [Parameter(ValueFromPipeline)]
        $queries
    )
    Begin {
        $results = @()
        $progress = 0
    }
    Process {
        $queries | ForEach-Object {
            $query = $_

            # Show progress
            $progress += 20
            if($progress -gt 100) { $progress = 0}
            $name = $query.RepositoryName
            Write-Progress -Activity "Fetching Issues..." -Status $name -PercentComplete $progress
            $q_hashtable = @{}
            $query.psobject.properties | Foreach { $q_hashtable[$_.Name] = $_.Value }
            if(-Not $q_hashtable['Assignee']) {
                $q_hashtable.remove('Assignee')
            }

            # Fetch data
            $issues = Get-GitHubIssue @q_hashtable
            $results += $issues
        }
    }
    End {
        return $results
    }
}

<#
.SYNOPSIS

Fetch GitHub issues assigned to user set in $ENV:GITHUB_USERNAME

.EXAMPLE

$issues = Get-AgileMine
$issues[0].updated_at
$issues[0].html_url
$issues[0..10] | Show-MarkdownFromGitHub

#>
function Get-AgileMine {
    param(
        [string]$repos
    )
    $myself = Get-AgileUser
    $queries = Get-AgileQuery -Assignee $myself -sort "updated" -direction "Ascending" -repos $repos
    $issues = Invoke-AgileQuery -queries $queries
    return $issues
}

<#
.SYNOPSIS

Fetch GitHub issues starting with the oldest updated date.

.EXAMPLE

$oldest = Get-AgileOldest
$oldest[0].updated_at
$oldest[0].html_url
$oldest[0..10] | Show-MarkdownFromGitHub

#>
function Get-AgileOldest {
    $issues = Invoke-AgileQuery -queries (
        Get-AgileQuery -sort "updated" -direction "Ascending"
    )
    return $issues
}

<#
.SYNOPSIS

Select GitHub issues that are tagged to discuss at the Stand Up meeting.

#>
function Select-AgileToDiscuss {
    begin{
        $results = @()
    }
    process{
        foreach ($label in $_.labels) {
            if($label.name -Contains "DiscussAtStandUp") {
                $results += $_
            }
        }
        if($_.labels -Contains 'DiscussAtStandUp') {
        }
    }
    end{
        return $results
    }
}

<#
.SYNOPSIS

Filter to closed GitHub issues last updated within the given date range.

.EXAMPLE

$qclosed = Get-AgileQuery -state 'Closed'
$closed = $qclosed | Invoke-AgileQuery | Select-AgileByAge -days_ago $days_ago

#>
function Select-AgileByAge {
    param(
        [string]$updated,
        [int]$days_ago
    )
    begin {
        $results = @()
        if($days_ago -And $updated) {
            thow "-Updated and -DaysAgo cannot be used together."
        }
        if($days_ago){
            $to_dt = (Get-Date).Add(900) # Set to far future to ignore.
            $from_dt = (Get-Date).AddDays(0 - $days_ago)
        }
        if($updated){
            $from, $to = $updated.replace('..', '|').split('|')
            $from_dt = Get-Date -Date $from
            $to_dt = Get-Date -Date $to
        }
    }
    process {
        if(($_.updated_at -gt $from_dt) -And ($_.updated_at -lt $to_dt)) {
            $results += $_
        }
    }
    end {
        return $results
    }
}


<#
.SYNOPSIS

Filter GitHub issues for those with an empty milestone field.

#>
function Select-AgileNoMilestone {
    begin {
        $results = @()
    }
    process {
        if($null -eq $_.milestone) {
         $results += $_
        }
    }
    end {
        return $results
    }
}

<#
.SYNOPSIS

Show open GitHub issues with no milestone assigned.

#>
function Show-AgileNoMilestone {
    $queries = Get-AgileQuery -State 'Open'
    $issues = Invoke-AgileQuery -queries $queries
    $issues = $issues | Select-AgileNoMilestone
    $issues | Show-MarkdownFromGitHub
}

<#
.SYNOPSIS

Filter to GitHub issues without a T-Shirt size label.

.DESCRIPTION

Issues labeled with 'Size XS' through 'Size L' are removed by this filter.

Issues labeled with 'Size XL' or 'Size XXL' are kept, as they need split.

Equivalent search in GitHub is:

is:open is:issue -label:'Size M' -label:'Size L' -label:'Size S' -label:'Size XS'


#>
function Select-AgileUnsized {
    begin {
        $results = @()
    }
    process {
        if(-Not $_.labels -Contains 'Size XS' -And
        -Not $_.labels -Contains 'Size S' -And
        -Not $_.labels -Contains 'Size M' -And
        -Not $_.labels -Contains 'Size L') {
            $results += $_
        }
    }
    end {
        return $results
    }
}
<#
.SYNOPSIS

Show GitHub issues without a T-Shirt size label.

#>
function Show-AgileUnsized {
    $queries = Get-AgileQuery -State 'Open'
    $issues = Invoke-AgileQuery -queries $queries
    $issues = $issues | Select-AgileUnsized
    $issues | Show-MarkdownFromGitHub
}

<#
.SYNOPSIS

Display Get-AgileToDiscuss results as Markdown.

#>
function Show-AgileToDiscuss {
    $queries = Get-AgileQuery -State 'Open'
    $issues = Invoke-AgileQuery -queries $queries
    $issues = $issues | Select-AgileToDiscuss
    $issues | Show-MarkdownFromGitHub
}

<#
.SYNOPSIS

Display Get-AgileByAge results as Markdown.

.EXAMPLE

Show-AgileByAge | Out-File SeptIssues.md


#>
function Show-AgileByAge {
    param(
        [string]$updated,
        [int]$days_ago,
        [string]$state = "Open"
    )
    $queries = Get-AgileQuery -State $state 
    $issues = Invoke-AgileQuery -queries $queries
    if($updated) {
        $issues = $issues | Select-AgileByAge -updated $updated
    }
    if($days_ago) {
        $issues = $issues | Select-AgileByAge -days_ago $days_ago 
    }
    $issues | Show-MarkdownFromGitHub
}

<#
.SYNOPSIS

Display Get-AgileMine results as Markdown.

.EXAMPLE

Show-AgileMine | Out-File MyIssues.md

.EXAMPLE

Show-AgileMine -DaysAgo 14 | Out-File MyStaleIssues.md

#>
function Show-AgileMine {
    param(
        [string]$repos,
        [int]$DaysAgo = -1
    )
    $my_issues = Get-AgileMine -repos $repos
    if($DaysAgo -eq -1) {
        $issues = $my_issues
    } else {
        $issues = $my_issues | Select-AgileByAge -days_ago $DaysAgo
    }
    $issues | Show-MarkdownFromGitHub
}


<#
.SYNOPSIS

Display Get-AgileOldest results as Markdown.

.EXAMPLE

Show-AgileOldest | Out-File OldestIssues.md

.EXAMPLE

Show issues last updated in 2021.

Show-AgileOldest -updated 2021.01.01..2021.12.30

.EXAMPLE

Show issues, oldest first, updated in the last 60 days.

Show-AgileOldest -days_ago 60

#>
function Show-AgileOldest {
    param(
        [string]$updated,
        [int]$days_ago
    )
    if($updated -Or $days_ago){
        Get-AgileOldest | Select-AgileByAge -days_ago $days_ago -updated $updated | Show-MarkdownFromGitHub
    }
    else {
        Get-AgileOldest | Show-MarkdownFromGitHub
    }
}

<#
.SYNOPSIS

Output Markdown of some agile sprint statistics.

.DESCRIPTION

Outputs these statistics.

- Closed issues updated in the last two weeks.
- Count of issues not assigned to any GitHub Milestone.
- Count of unsized issues across all repositories.

.EXAMPLE

Use the -list flag to also output lists containing each issue in Markdown
 link format.

Show-AgileStats -list

#>
function Show-AgileStats(){
    param(
        [switch]$list = $false
    )
    "## Agile State"

    $qclosed = Get-AgileQuery -state 'Closed'
    $closed = $qclosed | Invoke-AgileQuery | Select-AgileByAge -days_ago 14
    $closed_count = ($closed | Measure-Object).Count

    $qopen = Get-AgileQuery -state 'Open'
    $open = $qopen | Invoke-AgileQuery

    $orphans = $open | Select-AgileNoMilestone
    $orphans_count = ($orphans | Measure-Object -Property updated_at -Min -Max).Count

    $unsized = $open | Select-AgileUnsized
    $unsized_count = ($unsized | Measure-Object).Count

    ""
    "+ Closed Issues this Sprint: $closed_count"
    "+ Count of Unsized Issues: $unsized_count"
    "+ Count of Issues with no milestone: $orphans_count"

    if($list) {
        ""
        "## Closed Issues Updated this Sprint (Show-AgileClosed)"
        $closed | Show-MarkdownFromGitHub
        ""
        "## Unsized Issues (Show-AgileUnsized)"
        $unsized | Show-MarkdownFromGitHub
        ""
        "## Issues with No Milestone (Show-AgileNoMilestone)"
        $orphans | Show-MarkdownFromGitHub
    }

}

function Show-AgileClosed {
    param(
        [int]$days_ago = 14
    )
    $qclosed = Get-AgileQuery -state 'Closed'
    $closed = $qclosed | Invoke-AgileQuery | Select-AgileByAge -days_ago $days_ago
    $closed | Show-MarkdownFromGitHub
}

# Export Core Functions
Export-ModuleMember -Function Get-AgileRepo
Export-ModuleMember -Function Get-AgileUser
Export-ModuleMember -Function Get-AgileQuery
Export-ModuleMember -Function Invoke-AgileQuery

# Export Select- and Get- functions.
Export-ModuleMember -Function Select-AgileByAge
Export-ModuleMember -Function Get-AgileMine
Export-ModuleMember -Function Get-AgileOldest
Export-ModuleMember -Function Select-AgileNoMilestone
Export-ModuleMember -Function Select-AgileToDiscuss
Export-ModuleMember -Function Select-AgileUnsized 

# Export Show- functions.
Export-ModuleMember -Function Show-AgileByAge
Export-ModuleMember -Function Show-AgileMine
Export-ModuleMember -Function Show-AgileNoMilestone
Export-ModuleMember -Function Show-AgileOldest
Export-ModuleMember -Function Show-AgileStats
Export-ModuleMember -Function Show-AgileToDiscuss
Export-ModuleMember -Function Show-AgileUnsized
Export-ModuleMember -Function Show-AgileClosed
