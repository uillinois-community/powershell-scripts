#
# So, currently developing this as a set of useful functions, fire 
# up ISE and make a list, then edit that list to what you like (should be two seperate scripts int he long run


function Find-Local-Repository-Directories {

  param(
      [Parameter(Mandatory=$true)]
    $StartingPath
  )

  return (Get-ChildItem source -Recurse -Directory -Attributes Hidden,!Hidden | Where-Object { $_.Name -eq '.git' } | %{ $_.Parent })


}

function Get-Git-Remotes {

  param(
    [Parameter(Mandatory=$true)]
    [string[]]$Paths
  )

  foreach ($path in $paths ) {
    
    Set-Location -Path  $path
    $all_remotes = git remote -v 
    
    $origins = $all_remotes | Where { $_ -match '^origin\s' }

    # So, we'll want to update fetch and pull remote urls bh swapping all but the 
    #
    # origin	ssh://git@code.library.illinois.edu:7999/ninja/design-directory.git (fetch)
    # origin	ssh://git@code.library.illinois.edu:7999/ninja/design-directory.git (push)

    foreach ( $remote_target in $origins ) {
        $naem, $url, $type_raw = $remote_target -split "`t"
        $type = $type_raw -replace '[()]',''
        Write-Output "git remote rename origin old-origin"
    }
      
  }
}

