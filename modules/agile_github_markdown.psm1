<#

Functions that fetch GitHub issues according to common agile practices, 
and display them as Markdown.

These rely on the github_for_agile module to fetch data across repositories,
and on the github_to_markdown module to output results as Markdown.

See github_for_agile for required environment variable configuration.

#>

<#
.SYNPOSIS

Display Get-AgileToDiscuss results as Markdown.

#>
function Show-AgileToDiscuss {
    Get-AgileToDiscuss | Show-GHIssuesAsMarkdown
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
        [switch]$closed
    )
    Get-AgileByAge -closed $closed -updated $updated -days_ago $days_ago | Show-GHIssuesAsMarkdown
}

<#
.SYNOPSIS

Display Get-AgileOldIssues results as Markdown.

.EXAMPLE

Show-AgileOldest | Out-File OldestIssues.md

#>
function Show-AgileOldest {
    Get-AgileOldest | Show-GHIssuesAsMarkdown
}



# Export various functions.
Export-ModuleMember -Function Show-AgileToDiscuss
Export-ModuleMember -Function Show-AgileByAge
Export-ModuleMember -Function Show-AgileOldest