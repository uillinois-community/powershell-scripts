BeforeAll {
    Mock -CommandName Get-AgileRepos { 
        return @('org1/repo1', 'org2/repo2')
    }
    $json = @'
    [
        {
            "html_url":  "https://example.com/964",
            "title":  "Work smarter.",
            "number":  964
        },
        {
            "html_url":  "https://example.com/965",
            "title":  "Work less hard.",
            "number":  965
        }]
'@
    $issues = $json | ConvertFrom-Json
    Mock -CommandName Get-GitHubIssue { return $issues }
}

Describe 'Get-AgileQueries' {
    It 'Returns paramaters to find closed issues this sprint' {
        # Assemble
        $expected_queries = @(
            @{
                OwnerName = 'org1'
                RepositoryName = 'repo1'
                State = 'closed'
            },
            @{
                OwnerName = 'org2'
                RepositoryName = 'repo2'
                State = 'closed'
            }
        )

        # Act
        $queries = Get-AgileQueries -Closed

        # Assert
        $queries.Count | Should -Be 2
        $expected_queries.Keys | ForEach-Object {
            $queries[$_] | Should -Be $expected_queries[$_]
        }

    }
}

Describe 'Invoke-AgileQueries' {
    It 'Calls Get-GitHubIssue with the expected params.' {
        # Assemble
        $queries = @(
            @{
                OwnerName = 'org1'
                RepositoryName = 'repo1'
                State = 'closed'
            },
            @{
                OwnerName = 'org2'
                RepositoryName = 'repo2'
                State = 'closed'
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
                State = 'open'
                Sort = 'updated'
                Direction = 'Descending'
                Assignee = 'tstark'
            },
            @{
                OwnerName = 'org2'
                RepositoryName = 'repo2'
                State = 'open'
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