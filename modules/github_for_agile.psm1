<#

.DESCRIPTION

Build and invoke lists of queries for use with Get-GitHubIssues, to help 
reliably search all repositories that are of interest to you.

Relies $ENV:GITHUB_REPOS being set in the environment.

.EXAMPLE

$ENV:GITHUB_REPOS = @('org/repo1', 'org2/repo2')

#>

<#
.SYNOPSIS

Call this to verify your $ENV:GITHUB_REPOS variable is set correctly for this 
module.

.EXAMPLE

$ENV:GITHUB_REPOS = @('org/repo1', 'org2/repo2')
Get-AgileRepos

#>
function Get-AgileRepos {
    return $ENV:GITHUB_REPOS.split(" ")
}

<#

.SYNOPSIS

Get queries to pass to Get-GitHubIssues based on your $ENV:GITHUB_REPOS
environment setting.

.EXAMPLE

$ENV:GITHUB_REPOS = @('org/repo1', 'org2/repo2')
$issues = @()
$queries = Get-AgileQueries -closed
$queries | ForEach-Object { 
    $issues += Get-GitHubIssue $_
}
($issues | Measure-Object).Count

#>
function Get-AgileQueries {
    param(
        [switch]$closed,
        [switch]$open,
        [switch]$mine,
        [string]$assignee,
        [string]$sort = "updated",
        [string]$direction = "Descending"
    )
    $queries = @()
    Get-AgileRepos | ForEach-Object {
        $owner, $repo = $_.split('/')
        $state = 'open'
        if($closed){
            $state = 'closed'
        }
        $query = @{
            OwnerName = $owner
            RepositoryName = $repo
            State = $state
            Sort = $sort
            Direction = $direction
        }
        if($mine) {
            $query['Assignee'] = $ENV:GITHUB_USERNAME
        }
        if($assignee) {
            $query['Assignee'] = $assignee
        }
        $queries += $query
    }
    return $queries
}

<#

.SYNPOSIS

Invoke queries with Get-GitHubIssues, gathering the returned issue objects.
Typically used with Get-AgileQueries.

.EXAMPLE

$ENV:GITHUB_REPOS = @('org/repo1', 'org2/repo2')
$issues = Invoke-AgileQueries -queries (Get-AgileQueries -closed)
($issues | Measure-Object).Count
$issues | Show-GHIssuesAsMarkdown

#>
function Invoke-AgileQueries {
    param(
        [hashtable[]]$queries
    )
    $results = @()
    $queries | ForEach-Object {
        $query = $_
        $issues = Get-GitHubIssue @query
        $results += $issues
    }
    return $results
}

<#
.SYNPOSIS

Fetch GitHub issues starting with the oldest updated date.

#>
function Get-AgileOldest {
    $issues = Invoke-AgileQueries -queries (
        Get-AgileQueries -sort "updated" -direction "Ascending"
    )
    return $issues
}

<#
.SYNPOSIS

Fetch GitHub issues that are tagged to discuss at the Stand Up meeting.

#>
function Get-AgileToDiscuss {
    $issues = Invoke-AgileQueries -queries (Get-AgileQueries)
    $issues = $issues | Where-Object { $_.labels -Contains 'DiscussAtStandUp' }
    return $issues
}

<#
.SYNPOSIS

Fetch closed GitHub issues last updated within the given date range.

.EXAMPLE

$issues = Get-AgileClosed -updated 2021-07-01..2021-09-19
$issues.Count

.EXAMPLE

$issues = Get-AgileClosed -days_ago 14
$issues.Count

#>
function Get-AgileByAge {
    param(
        [string]$updated,
        [int]$days_ago,
        [switch]$closed
    )
    $issues = Invoke-AgileQueries -queries (Get-AgileQueries -closed $closed)
    if($updated){
        $from, $to = $updated.split('..')
        $issues = $issues | Where-Object { $_.updated_at -gt $from }
        $issues = $issues | Where-Object { $_.updated_at -lt $to }
    }
    if($days_ago){
        $from = (Get-Date).AddDays(0 - $days_ago)
        $issues = $issues | Where-Object { $_.updated_at -gt $from }
    }
    return $issues
}


# Export Core Functions
Export-ModuleMember -Function Get-AgileRepos
Export-ModuleMember -Function Get-AgileQueries
Export-ModuleMember -Function Invoke-AgileQueries

# Export Various Queries
Export-ModuleMember -Function Get-AgileToDiscuss
Export-ModuleMember -Function Get-AgileByAge
Export-ModuleMember -Function Get-AgileOldest