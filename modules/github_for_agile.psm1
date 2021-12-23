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
        [switch]$mine,
        [string]$assignee,
        [string]$sort = "updated",
        [string]$state = 'Open',
        [string]$direction = "Descending"
    )
    $queries = @()
    Get-AgileRepos | ForEach-Object {
        $owner, $repo = $_.split('/')
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
.SYNOPSIS

Fetch GitHub issues starting with the oldest updated date.

.EXAMPLE

$oldest = Get-AgileOldest
$oldest[0].updated_at
$oldest[0].html_url
$oldest[0..10] | Show-GHIssuesAsMarkdown

#>
function Get-AgileOldest {
    $issues = Invoke-AgileQueries -queries (
        Get-AgileQueries -sort "updated" -direction "Ascending"
    )
    return $issues
}

<#
.SYNPOSIS

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
.SYNPOSIS

Fetch closed GitHub issues last updated within the given date range.

.EXAMPLE

$issues = Get-AgileByAge -updated 2021-07-01..2021-09-19
$issues.Count

.EXAMPLE

$issues = Get-AgileByAge -days_ago 14
$issues.Count

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
            Write-Host "Updated $updated"
            $from, $to = $updated.replace('..', '|').split('|')
            Write-Host "To $to"
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


# Export Core Functions
Export-ModuleMember -Function Get-AgileRepos
Export-ModuleMember -Function Get-AgileQueries
Export-ModuleMember -Function Invoke-AgileQueries

# Export Various Queries
Export-ModuleMember -Function Select-AgileToDiscuss
Export-ModuleMember -Function Select-AgileByAge
Export-ModuleMember -Function Get-AgileOldest