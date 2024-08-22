<#
 .Synopsis
  Gets metadata for repositories that are public that have a .github directory 

 .Description
  Gets repositories that are public that have a .github/workflow directory in the default branch.
   Expectes  a Github finge-grained token that has access 
  to all repositories in the organization for the Metadata permission stored in environment variable GITHUB_PS_TOKEN.

  At this time

 .Parameter OrganizationName
  Name of the Github organization.

 .Example

  Get-PublicReposWithGithubActions.ps1 -OrganizationName "MyOrganization"

  Gets all public repositories in the MyOrganization organization that have a .github/workflows directory in the default branch.

 .Notes 
 TODO:
  * Check more than default branch
  * Check various text files to see if can finda checkout and upload action, indicate higher priority to examine
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$OrganizationName
)


# This isn't great, because it doesn't check all branches and bad api key
# could lead to false negative 
Function Test-GitHubContentPathExists {

  param(
    [Parameter(Mandatory = $true)]
    $Repository,
    [Parameter(Mandatory = $true)]
    [string]$Path
    
    )

    try {
      $capture_output = $Repository | Get-GitHubContent  -Path $Path
    } catch {
      return $false
    }
    return $true
}

#TODO: - reset back to the value that it was before the script was run
# soem weird issues happening wtih the error handling and telemtry, so disablng for now
Set-GitHubConfiguration -DisableTelemetry -SessionOnly


Write-Output "Getting repositories for $OrganizationName that have Github Actions"
Write-Output "For more information see:"
Write-Output "  * https://answers.uillinois.edu/illinois/141284"
Write-Output "  * https://unit42.paloaltonetworks.com/github-repo-artifacts-leak-tokens/"
Write-Output ""

Get-GitHubRepository -OwnerName $OrganizationName | Where-Object { $_.visibility -eq "public" -and (Test-GitHubContentPathExists -Repository $_ -Path ".github/workflows" )} | ForEach-Object { 
  Write-Output "$($_.full_name)"
}





