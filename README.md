# github-powershell-scripts

## Prerequisites/Dependencies

### Powershell Module for Github

Most of the PowerShell modules require the Powershell module for Github.  

#### Installation

You can get latest release of the PowerShellForGitHub on the [PowerShell Gallery](https://www.powershellgallery.com/packages/PowerShellForGitHub)

```PowerShell
Install-Module -Name PowerShellForGitHub
```

----------

#### Configuration

To avoid severe API rate limiting by GitHub, you should configure the module with your own personal
access token.

1) Create a new API token by going to https://github.com/settings/tokens/new (provide a description
   and check any appropriate scopes)
2) Call `Set-GitHubAuthentication`, enter anything as the username (the username is ignored but
   required by the dialog that pops up), and paste in the API token as the password.  That will be
   securely cached to disk and will persist across all future PowerShell sessions.
If you ever wish to clear it in the future, just call `Clear-GitHubAuthentication`).

A number of additional configuration options exist with this module, and they can be configured
for just the current session or to persist across all future sessions with `Set-GitHubConfiguration`.
For a full explanation of all possible configurations, run the following:
a collection of useful powershell scripts used by Library IT at University of Illinois at Urbana-Champaign to manage our github organizations.

## Instructions

Clone the Reposistory

```Powershell
git clone https://github.com/uillinois-community/powershell-scripts
```

Load all of the modules.

```Powershell
cd github-powershell-scripts
Get-ChildItem ./modules/ | import-module -verbose
```

Add the scripts to your path.

```Powershell
cd bin
$ENV:PATH = "$ENV:PATH;$(Get-Location)"
```
