<#

.EXAMPLE

$issues = Get-GitHubIssues <...params...>
$issues | Show-GHIssuesAsMarkdown

#>
function Show-GHIssuesAsMarkdown() {
  process
	{
    # Markdown output
    " + [" + $_.Title + " (" + $_.Number + ")](" + $_.html_url + ")" 
  }
}

Export-ModuleMember -Function Show-GHIssuesAsMarkdown