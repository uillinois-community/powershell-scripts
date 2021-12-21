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
.SYNPOSIS

Display Get-AgileClosed results as Markdown.

#>
function Show-AgileClosed {
    param(
        [string]$updated,
        [int]$days_ago
    )
    Get-AgileClosed -updated $updated -days_ago $days_ago | Show-GHIssuesAsMarkdown
}

# Export various functions.
Export-ModuleMember -Function Show-AgileToDiscuss
Export-ModuleMember -Function Show-AgileClosed