# GitHub Markdown Helpers Module

## About

This library provides a set of opinionated commands for pulling lists of
GitHub issues as Markdown text to your terminal. Typical usage is to redirect
the output into a `.md` file, and then generate your desired attractive output
(often PDF or HTML).

## Commands

Capture work completed in the last sprint.
Show-GHClosed shows closed GitHub issues updated in the last 14 days.

Look for work that might be slipping off of my radar.
Show-GHMine shows open GitHub issues assigned to $env:GITHUB_USERNAME with 
no activity in the last 24 hours.

List issues that need to be sized by the team.
Get/Show-GHUnsized shows open issues with no labels from the set 'XS', 'S', 'M',
'L', 'XL'. 'XXL' is intentionally included in the output as it needs resized.

Show-GHToDiscuss shows open issues with the label 'DiscussAtStandUp'.

Show-GHNoMilestone shows issues that are not part of any GitHub milestone.

These commands each have a matching 'Get-' command in case you want to work with
that data set in PowerShell.

## Usage Example

```powershell
PS> Show-GHMine
 + [Issue Title (901)](https://github.com/organization/repository/issues/901)
 + [Issue Title (902)](https://github.com/organization/repository/issues/902)
```

## Dependencies

This library depends on the [PowerShellForGitHub](https://github.com/microsoft/PowerShellForGitHub) module.

This PowerShell module requires the following environment variables to be set 
in your PowerShell profile:

```powershell
$env:GITHUB_USERNAME = 'github_username'
$env:GITHUB_ORG = 'github_organization_name'
$env:GITHUB_REPOS = @('repository1', 'repository2', 'repository3')
```
