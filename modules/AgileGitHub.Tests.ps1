Describe 'Get-AgileRepo'  {
    BeforeAll {
        # $ENV:GITHUB_REPOS = "org1/repo1 org2/repo2 org2/repo3"
        $ENV:GITHUB_REPOS = @("org1/repo1", 
                              "org2/repo2", 
                              "org2/repo3") -join ' '
        # equivalent to $ENV:GITHUB_REPOS = "org1/repo1 org2/repo2 org2/repo3"
    }
    It 'Returns a list of repositories' {
        $repos = Get-AgileRepo
        $repos[0].OwnerName| Should -Be 'org1'
        $repos[0].RepoName | Should -Be 'repo1'
        $repos[1].OwnerName| Should -Be 'org2'
        $repos[1].RepoName | Should -Be 'repo2'
        $repos[2].OwnerName| Should -Be 'org2'
        $repos[2].RepoName | Should -Be 'repo3'
    }
    It 'Skips requested repositories' {
        $repos = Get-AgileRepo -repos 'org1/repo1 org2/repo3'
        $repos[0].OwnerName| Should -Be 'org1'
        $repos[0].RepoName | Should -Be 'repo1'
        $repos[1].OwnerName| Should -Be 'org2'
        $repos[1].RepoName | Should -Be 'repo3'
    }
}
Describe 'Get-AgileQuery' {
    BeforeAll {
        Mock -CommandName Get-GitHubIssue { return $issues }
    }

    It 'Returns expected queries' {
        # Act
        $tested = Get-AgileQuery -repos "org1/repo1 org2/repo2 org2/repo3"

        # Assert
        $tested.Count | Should -Be 3
        $tested[0].OwnerName | Should -Be 'org1'
    }
    It 'Sets Assignee' {
        # Act
        $tested = Get-AgileQuery -repos 'org5/repo5' -assignee tstark

        # Assert
        $tested[0].OwnerName | Should -Be 'org5'
        $tested[0].RepositoryName | Should -Be 'repo5'
        $tested[0].Assignee | Should -Be 'tstark'
    }
}

Describe 'Invoke-AgileQuery' {
    BeforeAll {
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

    It 'Calls Get-GitHubIssue once per repo' {
        # Assemble
        $queries = @(
            [PSCustomObject]@{
                OwnerName = 'org1'
                RepositoryName = 'repo1'
                State = 'Closed'
                Assignee = $null
            },
            [PSCustomObject]@{
                OwnerName = 'org2'
                RepositoryName = 'repo2'
                State = 'Closed'
                Assignee = $null
            }
        )

        # Act
        Invoke-AgileQuery -Queries $queries

        # Asset
        Should -Invoke -CommandName Get-GitHubIssue -Times 2
    }

    It 'Calls Get-GitHubIssue without Assignee if blank' {
        # Assemble
        $queries = @(
            [PSCustomObject]@{
                OwnerName = 'org1'
                RepositoryName = 'repo1'
                State = 'Closed'
                Assignee = $null
            }
        )

        # Act
        Invoke-AgileQuery -Queries $queries

        # Asset
        Should -Invoke -CommandName Get-GitHubIssue -Times 1 -ParameterFilter { 
            $OwnerName -eq 'org1'
        }
        Should -Invoke -CommandName Get-GitHubIssue -Times 1 -ParameterFilter { 
            $RepositoryName -eq 'repo1'
        }
        Should -Not -Invoke -CommandName Get-GitHubIssue -Times 1 -ParameterFilter { 
            $Assignee -eq $null
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
Describe 'Show-AgileMine' {
    BeforeAll {
        # Assemble
        $issues = @()
        Mock -CommandName Get-AgileUser { return 'tstark' }
        Mock -CommandName Get-AgileQuery {}
        Mock -CommandName Invoke-AgileQuery { }
        Mock -CommandName Show-MarkdownFromGitHub { }
    }
    It 'Invokes expected commands' {

        # Act
        Show-AgileMine

        # Assert
        Should -Invoke -CommandName Get-AgileUser -Times 1
        Should -Invoke -CommandName Get-AgileQuery -Times 1 -ParameterFilter {
            $assignee -eq 'tstark'
        }
    }
}