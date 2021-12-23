# Markdown from GitHub Module

## About

This library provides a commands to display GitHub issues fetched from the
 Get-GitHubIssue PowerShell command as inline Markdown.

Typical usage is to redirect the output into a `.md` file, and then generate
 the desired attractive output file (often PDF or HTML).

## Usage Example

```powershell
$issues = Get-GitHubIssue <...params...>
$issues | Show-MarkdownFromGitHub
 + [Issue Title (901)](https://github.com/organization/repository/issues/901)
 + [Issue Title (902)](https://github.com/organization/repository/issues/902)
```

## Dependencies

This library expects input that results from calling the `Get-GitHubIssue`
 method from [PowerShellForGitHub][23].

[23]: https://github.com/microsoft/PowerShellForGitHub

This library is also compatible with output from various commands in
 `AgileGitHub`, which itself uses this module for all `Show-` commands.
