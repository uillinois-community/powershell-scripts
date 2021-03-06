# GitHub Markdown Helpers Module

## About

This library provides a set of opinionated commands that perform common
 agile searches using the `Get-GitHubIssue` method in
 [PowerShellForGitHub][23].

## Command Types

The list of available commands can be generated with this command:

```PowerShell
Get-Command -Module AgileGitHub
```

Examples for specific commands can be fetched with this command:

```Powershell
Get-Help Select-AgileByAge -Examples
```

`Show-` commands in this module print their output as Markdown, using the
`MarkdownGitHub` module, along with `Get-` and `Select-` commands in this
 module.

`Select-` commands in this module help filter lists of GitHub issues.

The `Get-` commands in this module return lists of pre-built queries
 for use with the `Get-GitHubIssue` method from [PowerShellForGitHub][23].
The `Invoke-AgileQuery` command helps conveniently invoke a set of queries
 generated by the `Get-` commands.

> The only reason to use these instead of calling `Get-GitHubIssue` directly is
> if you wish to conveniently run the same query across multiple repositories.

[23]: https://github.com/microsoft/PowerShellForGitHub


## Dependencies

This library depends on the [PowerShellForGitHub](https://github.com/microsoft/PowerShellForGitHub) module.

This PowerShell module also requires the following environment variable to be
 set in your PowerShell profile:

```powershell
$env:GITHUB_REPOS = @(
    'OWNER/REPOSITORY'
    , 'OWNER/REPOSITORY'
    , 'OWNER/REPOSITORY'
)
```
