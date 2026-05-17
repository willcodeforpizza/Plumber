BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'ConvertTo-PlumberPathRegex' {
    It 'pins the regex for <Pattern> matches <SamplePath>=<Expected>' -ForEach @(
        # Resource/*.json - single-segment wildcard, single directory
        @{ Pattern = 'Resource/*.json'; SamplePath = 'Resource/foo.json'; Expected = $true }
        @{ Pattern = 'Resource/*.json'; SamplePath = 'Resource/sub/foo.json'; Expected = $false }
        @{ Pattern = 'Resource/*.json'; SamplePath = 'foo.json'; Expected = $false }
        @{ Pattern = 'Resource/*.json'; SamplePath = 'Resource/foo.yaml'; Expected = $false }

        # Resource/**/*.json - recursive directories
        @{ Pattern = 'Resource/**/*.json'; SamplePath = 'Resource/foo.json'; Expected = $true }
        @{ Pattern = 'Resource/**/*.json'; SamplePath = 'Resource/sub/foo.json'; Expected = $true }
        @{ Pattern = 'Resource/**/*.json'; SamplePath = 'Resource/a/b/foo.json'; Expected = $true }
        @{ Pattern = 'Resource/**/*.json'; SamplePath = 'other/foo.json'; Expected = $false }

        # **/foo.json - match anywhere
        @{ Pattern = '**/foo.json'; SamplePath = 'foo.json'; Expected = $true }
        @{ Pattern = '**/foo.json'; SamplePath = 'sub/foo.json'; Expected = $true }
        @{ Pattern = '**/foo.json'; SamplePath = 'a/b/foo.json'; Expected = $true }
        @{ Pattern = '**/foo.json'; SamplePath = 'foobar.json'; Expected = $false }

        # ? - single character
        @{ Pattern = 'log?.txt'; SamplePath = 'logA.txt'; Expected = $true }
        @{ Pattern = 'log?.txt'; SamplePath = 'log.txt'; Expected = $false }
        @{ Pattern = 'log?.txt'; SamplePath = 'logAB.txt'; Expected = $false }
        @{ Pattern = 'log?.txt'; SamplePath = 'sub/logA.txt'; Expected = $false }

        # Literal - no wildcards, exact match
        @{ Pattern = 'Resource/foo.json'; SamplePath = 'Resource/foo.json'; Expected = $true }
        @{ Pattern = 'Resource/foo.json'; SamplePath = 'Resource/fooXjson'; Expected = $false }
        @{ Pattern = 'Resource/foo.json'; SamplePath = 'Resource/foo.json.bak'; Expected = $false }

        # Backslash normalisation
        @{ Pattern = 'Resource\foo.json'; SamplePath = 'Resource/foo.json'; Expected = $true }
    ) {
        $params = @{
            Pattern    = $Pattern
            SamplePath = $SamplePath
            Expected   = $Expected
        }
        InModuleScope Plumber -Parameters $params {
            $regex = ConvertTo-PlumberPathRegex -Pattern $Pattern
            $because = "pattern '$Pattern' against '$SamplePath' (regex: $regex)"
            ($SamplePath -match $regex) | Should -Be $Expected -Because $because
        }
    }
}
