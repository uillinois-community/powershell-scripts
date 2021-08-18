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



function Set-GithubTeamPermissionsAllTeamRepos {
    param(
        [Parameter(Mandatory = $true)]
        $OrganizationName,
        [Parameter(Mandatory = $true)]
        $TeamName,
        [ValidateSet('Admin', 'Pull', 'Maintain', 'Push', 'Triage')]
        $Permission = 'Admin'
    )
  

    # $repos = Get-GithubTeamRepositories -OrganizationName $OrganizationName -TeamName $TeamName 
    # $repos | Add-Member -MemberType AliasProperty -Name RepositoryUrl -value html_url
    # $repos | Set-GitHubRepositoryTeamPermission -OwnerName $OrganizationName -TeamName $TeamName -Permission $Permission
  
    foreach ($repo in $repos) {
        Set-GitHubRepositoryTeamPermission -ownername $OrganizationName -TeamName $TeamName -Permission $Permission -RepositoryName $repo.name
    }   
}