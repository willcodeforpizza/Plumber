BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../Plumber.psd1" -Force
    }
}

Describe 'Changed file integration' {
    BeforeEach {
        $script:repoRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -Path $script:repoRoot -ItemType Directory -Force | Out-Null
        & git -C $script:repoRoot init --initial-branch main | Out-Null
        & git -C $script:repoRoot config user.email plumber@example.invalid
        & git -C $script:repoRoot config user.name Plumber

        Set-Content -Path (Join-Path $script:repoRoot 'committed.ps1') -Value '$true'
        & git -C $script:repoRoot add committed.ps1
        & git -C $script:repoRoot commit -m initial | Out-Null
        & git -C $script:repoRoot branch base
    }

    It 'gets staged, unstaged and untracked files' {
        Set-Content -Path (Join-Path $script:repoRoot 'committed.ps1') -Value '$false'
        Set-Content -Path (Join-Path $script:repoRoot 'staged.ps1') -Value '$true'
        Set-Content -Path (Join-Path $script:repoRoot 'untracked.ps1') -Value '$true'
        & git -C $script:repoRoot add staged.ps1

        InModuleScope Plumber -Parameters @{RepoRoot = $script:repoRoot} {
            $files = Get-PlumberChangedFile -BuildRoot $RepoRoot

            $files.Name | Should -Contain 'committed.ps1'
            $files.Name | Should -Contain 'staged.ps1'
            $files.Name | Should -Contain 'untracked.ps1'
        }
    }

    It 'gets files changed from a diff base and skips deleted files' {
        Set-Content -Path (Join-Path $script:repoRoot 'base-change.ps1') -Value '$true'
        Remove-Item (Join-Path $script:repoRoot 'committed.ps1')
        & git -C $script:repoRoot add --all
        & git -C $script:repoRoot commit -m changed | Out-Null

        InModuleScope Plumber -Parameters @{RepoRoot = $script:repoRoot} {
            $files = Get-PlumberChangedFile -BuildRoot $RepoRoot -DiffBase base

            $files.Name | Should -Contain 'base-change.ps1'
            $files.Name | Should -Not -Contain 'committed.ps1'
        }
    }
}
