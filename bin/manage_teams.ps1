<#
 .Synopsis
 Grabs Repository information for Github team in a specific organization.
 
 .Description
 Grabs Repository information for Github team in a specific organization.
 
 .Parameter OrganizationName
 Name of the Github organization.
 
 .Parameter TeamName
 Name of the team in the Github organization.
 
 .Example
   # Get all information on repositories for team and organization
   Get-GithubTeamRepositories -OrganizationName myorgname -TeamName footeam
 
 .Example
   # Return repository names only
   (Get-GithubTeamRepositories -OrganizationName myorgname -TeamName footeam).name
#>
function Get-GithubTeamRepositories {
 
  param(
    [Parameter(Mandatory = $true)]
    $OrganizationName,
    [Parameter(Mandatory = $true)]
    $TeamName
  )

  $repo_url = (Get-GitHubTeam -OrganizationName $OrganizationName -TeamName $TeamName).repositories_url

  $uri_frag = $repo_url.Substring(23)

  $params = @{
    'Method'      = 'Get'
    'UriFragment' = "$($uri_frag)?per_page=1000"
  }

  Invoke-GHRestMethod @params 

}

<#
 .Synopsis
  Sets Repository permissions all repositories for specified Github team in a specific organization.

 .Description
  Sets Repository permissions all repositories for specified Github team in a specific organization.

 .Parameter OrganizationName
  Name of the Github organization.

 .Parameter TeamName
  Name of the team in the Github organization.

 .Parameter Permission
  Name of the team in the Github organization.

 .Example
   # Grant admin permission to all repositories for specified team and organization.
   Set-GithubTeamPermissionsAllTeamRepos -OrganizationName myorgname -TeamName footeam -Permission Admin

 .Example
   # Pipeline input example
  Get-GithubTeamRepositories -OrganizationName uiuc-exampleorg -TeamName test | Set-GithubTeamPermissionsAllTeamRepos -OrganizationName uiuc-exampleorg -TeamName test -Permission Admin
#>
function Set-GithubTeamPermissionsAllTeamRepos {
  param(
    [Parameter(Mandatory = $true)]
    $OrganizationName,
    [Parameter(Mandatory = $true)]
    $TeamName,
    [ValidateSet('Admin', 'Pull', 'Maintain', 'Push', 'Triage')]
    $Permission = 'Admin',
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [Alias(, 'Name')]
    $Repositories
  )
  
  
  Begin {}

  Process {
       
    foreach ($repo in $Repositories) {
      Set-GitHubRepositoryTeamPermission -ownername $OrganizationName -TeamName $TeamName -Permission $Permission -RepositoryName $repo
      Write-Output "Granted $($TeamName) $($Permission) permissions for repo $($repo)."
    } 

  }
  
  End {}

}