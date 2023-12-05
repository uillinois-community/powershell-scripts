<#

.DESCRIPTION

Invoke a GitHub CLI command in every repository configured in $env:GITHUB_REPOS

#>
function Invoke-AgileCmd { 
    param(
        [string]$gh_command
    )
    $env:GITHUB_REPOS_CLONED.split(' ') | ForEach-Object {
        $repo_path = "$env:GITHUB_CLONE_PATH/$_" 
        cd $repo_path
		Invoke-Expression $gh_command
    }
}

Export-ModuleMember -Function Invoke-AgileCmd
