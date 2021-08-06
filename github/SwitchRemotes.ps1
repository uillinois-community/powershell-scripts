#
# So, currently developing this as a set of useful function,
# don't really have a traditional script yet.
#
# How to use atm
#
# In a powershell terminal execute this script
# 
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




function Find-Local-Repository-Directories {

  param(
      [Parameter(Mandatory=$true)]
    $StartingPath
  )

  return (Get-ChildItem source -Recurse -Directory -Attributes Hidden,!Hidden | Where-Object { $_.Name -eq '.git' } | %{ $_.Parent })


}


# This assumes the repo name has remained the same. We might want to make this read in from a csv file or something

function Migrate-Git-Remotes {

  param(
    [Parameter(Mandatory=$true)]
    [string[]]$Paths,
    [Parameter(Mandatory=$true)]
    [string]$NewUrlBase,
    [switch]$DryRun 
  )


  if( -not ($NewUrlBase -match '/$' ) ) {
    $NewUrlBase += '/'
  } 
    


  foreach ($path in $paths ) {
    
    Set-Location -Path  $path
    $all_remotes = git remote -v 
    
    $origins = $all_remotes | Where { $_ -match '^origin\s' }

#    Write-Output $origins

    if( $origins.Length -gt 0 ) {
      if( $DryRun ) {
        Write-Output "Would run 'git remote rename origin old-origin'"
      }
      else {
        git remote rename origin old-origin
      }
      # So, we'll want to update fetch and pull remote urls bh swapping all but the 
      #
      # origin	ssh://git@code.library.illinois.edu:7999/ninja/design-directory.git (fetch)
      # origin	ssh://git@code.library.illinois.edu:7999/ninja/design-directory.git (push)

      # putting in Array to deal with the fact that this could end up with just one item, which powershell will then take out of the
      # array. We could also just test for the type of array later and throw exceptions then...
      $urls = @($origins | %{ (-split $_ )[1]} | Select -Unique)

      if( $urls.length -eq 0 ) {
        throw "$path has no remotes set..."
      }
      if( $urls.Length -gt 1 ) {
        throw "$path has different fetch and push, will not process automatically $urls  "

      }

      $repo_slug = [regex]::Match($urls[0],'/([^/]+)$').captures.groups[1].value

        

      $target_url = $NewUrlBase + $repo_slug
      
      if( $DryRun ) {
        Write-Output "would run 'git remote add origin $target_url'"
      }
      else {
        git remote add origin $target_url 
      }
     }
     
     Write-Output "Migrated $url to $target_url for $path" 
  }
}


function Reverse-Migration {
  param(
    [Parameter(Mandatory=$true)]
    [string]$Path
  )
  Set-Location -Path  $path

  git remote remove origin
  git remote rename old-origin origin

  Write-Output "Reversed migration for $path"

}

