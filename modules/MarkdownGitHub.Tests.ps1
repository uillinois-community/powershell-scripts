Describe 'Show-MarkdownFromGitHub' {
    It 'Outputs the expected markdown list.' {
        # Assemble
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

        $expected_markdown = @(
            ' + [Work smarter. (964)](https://example.com/964)', 
            ' + [Work less hard. (965)](https://example.com/965)'
            )

        # Act
        $markdown = $issues | Show-MarkdownFromGitHub

        # Assert
        $markdown | Should -Be $expected_markdown
    }
}