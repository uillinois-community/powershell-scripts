Describe 'Get-AgileQueries' {
    BeforeAll {
        Mock -CommandName Get-AgileRepos { 
            return @('org1/repo1', 'org2/repo2')
        }
        $json = @'
        [
            {
                "html_url":  "https://example.com/964",
                "title":  "Work smarter.",
                "number":  964,
                "updated_at": "10/13/2020 2:54:33 PM"
            },
            {
                "html_url":  "https://example.com/965",
                "title":  "Work less hard.",
                "number":  965,
                "updated_at": "10/13/2021 2:54:33 PM"
            }]
'@
        $issues = $json | ConvertFrom-Json
        Mock -CommandName Get-GitHubIssue { return $issues }
    }

    It 'Returns paramaters to find closed issues this sprint' {
        # Assemble
        $expected_query_1 = @{
            OwnerName = 'org1'
            RepositoryName = 'repo1'
            State = 'Open'
        }

        # Act
        $tested = Get-AgileQueries

        # Assert
        $tested.Count | Should -Be 2
        $tested_1 = $tested[0]

        $expected_query_1.Keys | ForEach-Object {
            $key = $_
            $tested_1[$key] | Should -Be $expected_query_1[$key]
        }
    }
}

Describe 'Invoke-AgileQueries' {
    BeforeAll {
        Mock -CommandName Get-GitHubIssue { return $issues }
        Mock -CommandName Get-AgileRepos { 
            return @('org1/repo1', 'org2/repo2')
        }
    }
    It 'Calls Get-GitHubIssue with the expected params.' {
        # Assemble
        $queries = @(
            @{
                OwnerName = 'org1'
                RepositoryName = 'repo1'
                State = 'Closed'
            },
            @{
                OwnerName = 'org2'
                RepositoryName = 'repo2'
                State = 'Closed'
            }
        )

        # Act
        Invoke-AgileQueries -Queries $queries

        # Asset
        Should -Invoke -CommandName Get-GitHubIssue -Times 2

    }

    It 'Sets Assignee' {
        # Assemble
        $expected_queries = @(
            @{
                OwnerName = 'org1'
                RepositoryName = 'repo1'
                State = 'Open'
                Sort = 'updated'
                Direction = 'Descending'
                Assignee = 'tstark'
            },
            @{
                OwnerName = 'org2'
                RepositoryName = 'repo2'
                State = 'Open'
                Sort = 'updated'
                Direction = 'Descending'
                Assignee = 'tstark'
            }
        )

        # Act
        $queries = Get-AgileQueries -Assignee tstark

        # Assert
        $queries.Count | Should -Be 2
        $expected_queries.Keys | ForEach-Object {
            $queries[$_] | Should -Be $expected_queries[$_]
        }

    }

}

Describe 'Select-AgileByAge' {
    It 'Handles -Updated' {
        # Assemble
        $issues = @(
            @{
                updated_at = Get-Date -Date "10/13/2020 2:54:33 PM"
            },
            @{
                updated_at = Get-Date -Date "10/13/2020 2:54:33 PM"
            },
            @{
                updated_at = Get-Date -Date "10/13/2021 2:54:33 PM"
            }
        )

        # Act
        $tested = $issues | Select-AgileByAge -updated 2020-01-01..2020-12-19 

        # Assert
        $tested.Count | Should -Be 2
    }
    It 'Handles -Days_Ago' {
        # Assemble
        $issues = @(
            @{
                updated_at = (Get-Date).addDays(-12)
            },
            @{
                updated_at = (Get-Date).addDays(-13)
            },
            @{
                updated_at = (Get-Date).addDays(-14)
            },
            @{
                updated_at = (Get-Date).addDays(-15)
            }
        )

        # Act
        $tested = $issues | Select-AgileByAge -Days_Ago 14

        # Assert
        $tested.Count | Should -Be 2
    }

}
Describe 'Select-AgileToDiscuss' {
    It 'Finds label DiscussAtStandUp' {
        # Assemble
        $issues = @(
            @{
                labels = @(@{name="DiscussAtStandUp"})
                updated_at = Get-Date -Date "10/13/2020 2:54:33 PM"
            },
            @{
                labels = @(@{name="DiscussAtStandUp"})
                updated_at = Get-Date -Date "10/13/2020 2:54:33 PM"
            },
            @{
                labels = @()
                updated_at = Get-Date -Date "10/13/2021 2:54:33 PM"
            }
        )

        # Act
        $tested = $issues | Select-AgileToDiscuss

        # Assert
        $tested.Count | Should -Be 2
    }
}

<#
.SYNOPSIS

Display Get-AgileToDiscuss results as Markdown.

#>
function Show-AgileToDiscuss {
    $queries = Get-AgileQueries -State 'Open'
    $issues = Invoke-AgileQueries -queries $queries
    $issues = $issues | Select-AgileToDiscuss
    $issues | Show-MarkdownFromGitHub
}

<#
.SYNOPSIS

Display Get-AgileByAge results as Markdown.

.EXAMPLE

Show-AgileByAge | Out-File SeptIssues.md


#>
function Show-AgileByAge {
    param(
        [string]$updated,
        [int]$days_ago,
        [string]$state = "Open"
    )
    $queries = Get-AgileQueries -State $state 
    $issues = Invoke-AgileQueries -queries $queries
    if($updated) {
        $issues = $issues | Select-AgileByAge -updated $updated
    }
    if($days_ago) {
        $issues = $issues | Select-AgileByAge -days_ago $days_ago 
    }
    $issues | Show-MarkdownFromGitHub
}

<#
.SYNOPSIS

Display Get-AgileOldIssues results as Markdown.

.EXAMPLE

Show-AgileOldest | Out-File OldestIssues.md

#>
function Show-AgileOldest {
    Get-AgileOldest | Show-MarkdownFromGitHub
}



# Export various functions.
Export-ModuleMember -Function Show-AgileToDiscuss
Export-ModuleMember -Function Show-AgileByAge
Export-ModuleMember -Function Show-AgileOldest