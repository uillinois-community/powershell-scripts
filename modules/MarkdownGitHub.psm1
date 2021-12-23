<#

.EXAMPLE

$issues = Get-GitHubIssues <...params...>
$issues | Show-MarkdownFromGitHub

#>
function Show-MarkdownFromGitHub() {
  process
	{
    # Markdown output
    " + [" + $_.Title + " (" + $_.Number + ")](" + $_.html_url + ")" 
  }
}

Export-ModuleMember -Function Show-MarkdownFromGitHub