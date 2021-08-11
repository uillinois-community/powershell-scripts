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
# PS> Switch-GitRemotes -Paths $paths -DryRun
#
# Does the result of that look reasonable? Remove the -DryRun flag and migrate
#
#
# If you migrated somethings you shouldn't have, there's the handy
# PS> Reverse-Migration -Path $paths

function Find-LocalRepositoryDirectories {

  param(
    $StartingPath = "."
  )

  return (Get-ChildItem $StartingPath -Recurse -Directory -Attributes Hidden, !Hidden | Where-Object { $_.Name -eq '.git' } | ForEach-Object { $_.Parent })


}


#This function checks if the remote is moved to github already.  It also checks if it can't find the repository on Github.
function Switch-Remotes {

  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Paths,
    [ValidateSet('git_url', 'ssh_url', 'clone_url')]
    [string[]]$URLType = "clone_url",
    [switch]$DryRun 
  )
  

  foreach ($path in $paths ) {
        
    $all_remotes = git --git-dir=$path\.git remote -v 
    
    $origins = $all_remotes | Where-Object { ($_ -notlike "*github.com*") -and ($_ -like "origin*") }
    if (!$origins) { 
      Write-Host "$($path.Split("\")[-1]) is already on github."
   }
   else {
       
      $urls = @($origins | ForEach-Object { (-split $_ )[1] } | Select-Object -Unique)
      
      if ( $urls.length -eq 0 ) {
        throw "$($path) has no remotes set..."
      }
      if ( $urls.Length -gt 1 ) {
        throw "$($path) has different fetch and push, will not process automatically $($urls)"

      }
      foreach ($url in $urls) {
        $repo = $url.Split("/")[-1].Split(".")[0]
        Write-Output "Checking Github Organization for Repository named $($repo)."
        try { $remote = Write-Output (Get-GitHubRepository -RepositoryName $repo).$URLType }
        catch { "Unable to find $($repo) on Github." }
      }
      if ( $remote ) {
        if ( $DryRun ) {
          Write-Output "Would run 'git remote rename origin old-origin'"
          Write-Output "git --git-dir=$($path)\.git remote rename origin old-origin"
          Write-Output "Switching to remote $($remote)"
          Write-Output "Would run 'git --git-dir=$($path)\.git remote add origin $($remote)'"
        }
        else {
          Write-Output "renaming origin to old-origin"
          git --git-dir=$($path)\.git remote rename origin old-origin
          Write-Output "Switching to remote $($remote)"
          git --git-dir=$($path)\.git remote add origin $($remote)
        }
      }
    }
  }
}

function Reset-Remotes {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Paths
  )
    
  foreach ($path in $paths ) {

    git --git-dir=$($path)\.git remote remove origin
    git --git-dir=$($path)\.git remote rename old-origin origin

    Write-Output "Reversed migration for $path"
  }
}


function Find-Remotes {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Paths
  )
    
  foreach ($path in $paths ) {

    $all_remotes = git --git-dir=$path\.git remote -v 

    $origins = $all_remotes | Where-Object { $_ -like "origin*" }

    $urls = @($origins | ForEach-Object { (-split $_ )[1] } | Select-Object -Unique)
    foreach ($url in $urls) {
            Write-Output "$($path.Split("\")[-1]) has remote $($url) set."

    }
  }
}