# PS> $all_paths = Find-Local-Repository-Directories -StartingPath the_path_you_want_to_list_repos_for
#
# Curate that list for paths you actually want to process...
#
# Manual approach
# $paths = @( url1, url2, ...)
#
# Filtered approach...
# $paths = $all_paths | Where { $_ -matches 'some_regex' }
#
# Then
# PS> Migrate-Git-Remotes -Paths $paths -NewUrlBase https://github.com/UIUCLibrary/ -DryRun
#
# Does the result of that look reasonable? Rmove the -DryRun flag and migrate
#
#
# If you migrated something you shouldn't have, there's the handy
# PS> Reverse-Migration -Path directory_path_to_revert

function Find-LocalRepositoryDirectories {

    param(
        $StartingPath = "."
    )

    return (Get-ChildItem $StartingPath -Recurse -Directory -Attributes Hidden, !Hidden | Where-Object { $_.Name -eq '.git' } | ForEach-Object { $_.Parent })


}


#This function checks if the remote is moved to github already.  It also checks if it can't find the repository on Github.
function Find-GitRemotes {

    param(
    [Parameter(Mandatory=$true)]
    [string[]]$Paths
  )

    foreach ($path in $paths ) {
        
    $all_remotes = git --git-dir=$path\.git remote -v 
    
    $origins = $all_remotes | Where-Object { ($_ -notlike "*github.com*") -and ($_ -like "origin*") }
        if (!$origins) { Write-Host "$($path.Split("\")[-1]) is already on github." }

    $urls = @($origins | ForEach-Object { (-split $_ )[1] } | Select-Object -Unique)
    
        foreach ($url in $urls) {
        $repo = $url.Split("/")[-1].Split(".")[0]
        Write-Output "Checking Github Organization for Repository named $($repo)."
        try {Write-Output (Get-GitHubRepository -RepositoryName $repo).clone_url}
        catch {"Unable to find $($repo) on Github."}
            }
    }
}