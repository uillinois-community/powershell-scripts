<#
 .Synopsis
  Executes gitleaks for Github Repositories and outputs as CSV in current directory. 

 .Description
  Executes gitleaks for Github Repositories and outputs as CSV in current directory. 

 .Parameter OrganizationName
  Name of the Github organization.

 .Parameter Credential
  Github username and enter PAT as password.
 
 .Parameter Repositories
  Repositories by name.  Accepts pipeline input.

 .Example
   # Run gitleaks for desired repo
   Invoke-Gitleaks -Credential colwell3 -OrganizationName fooorg -Repositories foorepo
 .Example
   # Run gitleaks for desired repo
   Get-GitHubRepository -Uri https://github.com/fooorg/foorepo | Invoke-Gitleaks -Credential colwell3 -OrganizationName fooorg

 .Example
   # Run gitleaks for all repositories in an organization
   Get-GitHubRepository -OrganizationName fooorg | Invoke-Gitleaks -Credential colwell3 -OrganizationName fooorg
#>
function Invoke-Gitleaks {
    param(
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty,
    [Parameter(Mandatory = $true)]
    $OrganizationName,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Alias(,'Name')]
    $Repositories
  )


    Begin {}

    Process {
      
    $UserName = $Credential.UserName
    $AccessToken = $Credential.GetNetworkCredential().Password

    if ((Get-Command "gitleaks.exe" -ErrorAction SilentlyContinue) -eq $null) { 
      Write-Host "Unable to find gitleaks.exe in your PATH. Install from https://github.com/zricethezav/gitleaks/releases/tag/v7.5.0"
      break
    }
        foreach ($RepositoryName in $Repositories) {
        cmd.exe /c "gitleaks --username=$($Username) --access-token=$($AccessToken)  --format=csv /o $($RepositoryName).csv  --repo-url=https://github.com/$($OrganizationName)/$($RepositoryName)"
        }
    
    }
 
    End {}
}