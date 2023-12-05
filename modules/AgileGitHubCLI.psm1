<#

.DESCRIPTION

Invoke a GitHub CLI command in every repository configured in $env:GITHUB_REPOS

See https://cli.github.com/manual/

Be sure to set $env:GITHUB_CLONE_PATH and $GITHUB_REPORS,
and run Invoke-AgileCloneAll first.

.EXAMPLE

Invoke-AgileCmd "gh issue list"

#>
function Invoke-AgileCmd { 
    param(
        [string]$gh_command
    )
    $env:GITHUB_REPOS.split(' ') | ForEach-Object {
		$folder = $_.split('/')[1]
        $repo_path = "$env:GITHUB_CLONE_PATH/$folder" 
        cd $repo_path
		Invoke-Expression $gh_command
    }
}
Export-ModuleMember -Function Invoke-AgileCmd

<#

.DESCRIPTION

Invoke a GitHub CLI command in every repository configured in $env:GITHUB_REPOS

#>
function Invoke-AgileCloneAll { 
    param(
        [string]$gh_command
    )
    $env:GITHUB_REPOS.split(' ') | ForEach-Object {
		$folder = $_.split('/')[1]
        $repo_path = "$env:GITHUB_CLONE_PATH/$folder" 
		if(-Not(Test-Path $repo_path)) {
			cd $env:GITHUB_CLONE_PATH
			$clone_cmd = "git clone git@github.com:$_"
			Invoke-Expression $clone_cmd
		}
    }
}
Export-ModuleMember -Function Invoke-AgileCmd
Export-ModuleMember -Function Invoke-AgileCloneAll