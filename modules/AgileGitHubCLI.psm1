<#

.SYNOPSIS

Invoke a GitHub CLI command in every repository configured in $env:GITHUB_REPOS

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
        Write-Host "$_"
		Invoke-Expression $gh_command
    }
}
Export-ModuleMember -Function Invoke-AgileCmd

<#

.SYNOPSIS

Invoke a GitHub CLI command outputing .json files for every repository
configured in $env:GITHUB_REPOS

.DESCRIPTION

Invoke a GitHub CLI command outputing .json files for every repository
configured in $env:GITHUB_REPOS

See https://cli.github.com/manual/

Be sure to set $env:GITHUB_CLONE_PATH and $GITHUB_REPORS,
and run Invoke-AgileCloneAll first.

.PARAMETER gh_command

A valid GitHub CLI command, such as `gh issue list`

.PARAMETER destination

The folder to save the created files.

.PARAMETER filename

A filename hint for the created files. Each repository name will also be included.

.PARAMETER ext

The extension for the created files. Defaults to `.json`

.EXAMPLE

Write-AgileToFile 'gh issue list --state closed --json title,milestone,closedAt'

Afterwards, the .json files can be used with typical PowerShell commands:

cat ~\data\gh_issues.example.json | ConvertFrom-Json |Format-Table

#>
function Write-AgileToFile { 
    param(
        [string]$gh_command="gh issue list --limit 1000 --search 'closed:2023-01-01..2024-01-01 -reason:not+planned' --state closed --json title,closedAt,url,milestone",
        [string]$data_dir="$HOME/data",
        [string]$filename='gh_issues',
        [string]$ext='json'
    )
    $env:GITHUB_REPOS.split(' ') | ForEach-Object {
		$folder = $_.split('/')[1]
        $repo_path = "$env:GITHUB_CLONE_PATH/$folder" 
        cd $repo_path
        $fileToWrite = "$data_dir/$filename.$folder.$ext"
        Write-Host "Writing $gh_command to $fileToWrite"
		Invoke-Expression $gh_command > $fileToWrite
    }
}
Export-ModuleMember -Function Write-AgileToFile

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