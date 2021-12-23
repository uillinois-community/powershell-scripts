<#
.SYNOPSIS

Functions that fetch GitHub issues according to common agile practices, 
and display them as Markdown.

.NOTES

This modules requires the following in your PowerShell profile:
$env:GITHUB_USERNAME = 'github_username'
$env:GITHUB_ORG = 'github_organization_name'
$env:GITHUB_REPOS = @('repository1', 'repository2', 'repository3')

.NOTES

These fucntions will be retired over time in favor of splitting their
functionality in a testable way across the github_for_agile, github_to_markdown,
and agile_github_markdown modules.

See agile_github_markdown for the easy-to-use functionality.

#>

function Get-GHEnvVars() {
  $orgs = $env:GITHUB_ORGS.split(" ")
  $repos = $env:GITHUB_REPOS.split(" ")
  return $orgs, $repos
}

<#

.EXAMPLE

$issues = Get-GHIssues -closed -updated 2021-09-20..2021-12-10 
$issues | Measure-Object
$issues | Show-MarkdownFromGitHub

#>
function Get-GHIssues() {
  param(
    [switch]$closed,
    [switch]$open,
    [string]$updated
  )
  $orgs, $repos = Get-GHEnvVars
  # TODO: Support multiple orgs
  # $issueSearchParams = @{ State = 'all'; OwnerName = $orgs[0] }
  $issueSearchParams = @{ State = 'open' }

  if($closed){
    $issueSearchParams['state'] = 'closed'
  }
  if($open){
    $issueSearchParams['state'] = 'open'
  }
  $issues = @()
  $repos | ForEach-Object { 
    $issues += Get-GitHubIssue -RepositoryName $_ @issueSearchParams
  }

  if($updated){
    $from, $to = $updated.split('..')
    Write-Host "Showing issues updated from $from to $to."
    $issues = $issues | Where-Object { $_.updated_at -gt $from }
    $issues = $issues | Where-Object { $_.updated_at -lt $to }
  }

  return $issues
}

<#
.SYNOPSIS

Show GitHub issues I am working on.

.EXAMPLE

Show issues assigned to $env:github_username 
that have not been updated in the past 14 days.

Show-GHMine -days 14

#>
function Show-GHMine() {
  param(
    [int]$days = 1
  )
  Get-GHMine -days $days | ForEach-Object {
    # Markdown output
    " + [" + $_.Title + " (" + $_.Number + ")](" + $_.html_url + ")"
  }
}

<#
.SYNOPSIS

Get GitHub issues that need sized.

.DESCRIPTION

Runs this GitHub search:
is:open is:issue -label:M -label:L -label:S -label:XL -label:XS 

#>
function Get-GHUnsized() {
  $repos = $env:GITHUB_REPOS.split(" ")
  $issueSearchParams = @{ State = 'open'; OwnerName = $env:GITHUB_ORG }
  $issues = @()
  $repos | ForEach-Object { 
    $issues += Get-GitHubIssue -RepositoryName $_ @issueSearchParams
  }

  # Ignore issues that have been updated in the last day.
  $issues = $issues | Where-Object { -Not $_.labels -Contains 'XS' }
  $issues = $issues | Where-Object { -Not $_.labels -Contains 'S' }
  $issues = $issues | Where-Object { -Not $_.labels -Contains 'M' }
  $issues = $issues | Where-Object { -Not $_.labels -Contains 'L' }
  # Leave XL issues, as they need split.

  return $issues
}

function Get-GHNoMilestone() {
  param(
    [string]$repository
  )
  $repos = $env:GITHUB_REPOS.split(" ")
  if($repository){
    $repos = @($repository)
  }
  $issueSearchParams = @{ State = 'open'; OwnerName = $env:GITHUB_ORG }
  $issues = @()
  $repos | ForEach-Object { 
    $issues += Get-GitHubIssue -RepositoryName $_ @issueSearchParams
  }

  # Get open issues with empty milestone
  $issues = $issues | Where-Object { $null -eq $_.milestone }
  return $issues
}
function Show-GHNoMilestone(){
  param(
    [string]$repository
  )
  Get-GHNoMilestone -Repository $repository | Show-MarkdownFromGitHub
}

function Show-GHUnsized() {
  Get-GHUnsized | ForEach-Object {
    # Markdown output
    " + [" + $_.Title + " (" + $_.Number + ")](" + $_.html_url + ")" + $_.labels
  }
}

function Get-GHByAssignee() {
  $repos = $env:GITHUB_REPOS.split(" ")
  $issueSearchParams = @{ State = 'open'; OwnerName = $env:GITHUB_ORG }
  $issues = @()
  $repos | ForEach-Object { 
    $issues += Get-GitHubIssue -RepositoryName $_ @issueSearchParams
  }

  # TODO: Group output by assignee.

  return $issues
}




function Show-GHToDiscuss() {
  Get-GHToDiscuss | Show-MarkdownFromGitHub
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

Use the -list flag to also output lists containing each issue in Markdown link format.

Show-SprintStats -list

.NOTES

Requires the following in your PowerShell profile:

$env:GITHUB_USERNAME = 'github_username'
$env:GITHUB_ORG = 'github_organization_name'
$env:GITHUB_REPOS = @('repository1', 'repository2', 'repository3')

#>
function Show-SprintStats(){
    param(
        [switch]$list = $false
    )
    Write-Host "## Stats"
    $closed = Get-GHClosed
    $closed_count = ($closed | Measure-Object).Count

    $orphans = Get-GHNoMilestone -repository SecOps-Tools
    $orphans_count = ($orphans | Measure-Object -Property updated_at -Min -Max).Count

    $unsized = Get-GHUnsized
    $unsized_count = ($unsized | Measure-Object).Count

    Write-Host "Closed Issues this Sprint: $closed_count"
    Write-Host "Count of Unsized Issues: $unsized_count"
    Write-Host "Count of Issues with no milestone: $orphans_count"

    if($list) {
        Write-Host "## Closed Issues Updated this Sprint (Show-GHClosed)"
        $closed | Show-MarkdownFromGitHub
        Write-Host "## Unsized Issues (Show-GHUnsized)"
        $unsized | Show-MarkdownFromGitHub
        Write-Host "## Issues with No Milestone"
        $orphans | Show-MarkdownFromGitHub
    }

}

Export-ModuleMember -Function Show-SprintStats
Export-ModuleMember -Function Get-GHIssues
Export-ModuleMember -Function Get-GHClosed
Export-ModuleMember -Function Show-GHClosed
Export-ModuleMember -Function Get-GHMine
Export-ModuleMember -Function Show-GHMine
Export-ModuleMember -Function Get-GHUnsized
Export-ModuleMember -Function Show-GHUnsized
Export-ModuleMember -Function Get-GHToDiscuss
Export-ModuleMember -Function Show-GHToDiscuss
Export-ModuleMember -Function Get-GHNoMilestone
Export-ModuleMember -Function Show-GHNoMilestone
Export-ModuleMember -Function Get-GHEnvVars