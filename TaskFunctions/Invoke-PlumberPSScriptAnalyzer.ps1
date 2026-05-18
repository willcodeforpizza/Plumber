function Invoke-PlumberPSScriptAnalyzer {
    <#
        .SYNOPSIS
        Runs the PSScriptAnalyzer task body.
    #>
    [CmdletBinding()]
    param ()

    $scriptFiles = @(
        Get-PlumberTaskFile -Task PSScriptAnalyzer -Extension '.ps1', '.psd1', '.psm1'
    )

    if (-not $script:PlumberConfig.Tasks.PSScriptAnalyzer.IncludeTests) {
        $testRoot = [System.IO.Path]::GetFullPath((Join-Path $BuildRoot 'Tests')).TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar
        )
        $testRootWithSeparator = "$testRoot$([System.IO.Path]::DirectorySeparatorChar)"
        $scriptFiles = @(
            $scriptFiles |
                Where-Object {
                    -not $_.FullName.Equals(
                        $testRoot,
                        [System.StringComparison]::OrdinalIgnoreCase
                    ) -and
                    -not $_.FullName.StartsWith(
                        $testRootWithSeparator,
                        [System.StringComparison]::OrdinalIgnoreCase
                    )
                }
        )
    }

    $settingsPath = Join-Path $BuildRoot 'PSScriptAnalyzerSettings.psd1'
    $settingsSplat = if (Test-Path $settingsPath) { @{ Settings = $settingsPath } } else { @{} }
    $scriptFailures = foreach ($file in $scriptFiles) {
        try {
            Invoke-ScriptAnalyzer $file.FullName @settingsSplat -ErrorAction Stop
        }
        catch {
            [pscustomobject]@{
                ScriptName = $file.Name
                Line       = 0
                RuleName   = 'InvokeScriptAnalyzer'
                Message    = $_.Exception.Message
            }
        }
    }

    $failures = foreach ($failure in $scriptFailures) {
        (
            "$($failure.ScriptName):$($failure.Line) - " +
            "$($failure.RuleName) - $($failure.Message)"
        )
    }
    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
