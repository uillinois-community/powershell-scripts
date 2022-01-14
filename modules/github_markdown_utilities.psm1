<#
.SYNOPSIS

Functions that fetch GitHub issues according to common agile practices, 
and display them as Markdown.

.DESCRIPTION

This module is being deprecated in favor of AgileGitHub, which
 accomplishes the same work in more testable ways.

AgileGitHub also requires fewer environment variables.

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
Export-ModuleMember -Function Get-GHUnsized
Export-ModuleMember -Function Show-GHUnsized
Export-ModuleMember -Function Get-GHNoMilestone
Export-ModuleMember -Function Show-GHNoMilestone
Export-ModuleMember -Function Get-GHEnvVars