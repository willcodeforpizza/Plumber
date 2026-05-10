<#
    .SYNOPSIS
    Validates PSScriptAnalyzer passes.

    .DESCRIPTION
    Runs PSScriptAnalyzer against PowerShell files under the build root and
    fails when analyzer diagnostics are returned.

    .GROUP
    CodeQuality

    .CONFIGURATION
    `IncludeTestsInPssa` controls whether files under `Tests` are analyzed. The
    default is `$true`.

    `ExcludePaths.PSScriptAnalyzer` excludes matching files from this task.

    PSScriptAnalyzer settings can be supplied at the build root in
    `PSScriptAnalyzerSettings.psd1`.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest     = 'MyModule.psd1'
        IncludeTestsInPssa = $false
        ExcludePaths       = @{
            PSScriptAnalyzer = @('Tests/Assets/*.ps1')
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task PSScriptAnalyzer
    ```

    .PASS
    ```powershell
    function Get-Thing {
        [CmdletBinding()]
        param ()
    }
    ```

    .FAIL
    ```powershell
    function get-thing {
    }
    ```
#>
Add-BuildTask -Name PSScriptAnalyzer -Jobs SetVariables, {
    # Scope can be lost when running Plumber on Plumber multiple times
    if (-not (Get-Command Get-PlumberTaskFile -ErrorAction SilentlyContinue)) {
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Test-PlumberTaskPathExcluded.ps1')
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberTaskFile.ps1')
    }

    $scriptFiles = @(
        Get-PlumberTaskFile -Task PSScriptAnalyzer -Extension '.ps1', '.psd1', '.psm1'
    )

    if (-not $script:PlumberConfig.IncludeTestsInPssa) {
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
