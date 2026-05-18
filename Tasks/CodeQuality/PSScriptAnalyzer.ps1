<#
    .SYNOPSIS
    Validates PSScriptAnalyzer passes.

    .DESCRIPTION
    Runs PSScriptAnalyzer against PowerShell files under the build root and
    fails when analyzer diagnostics are returned.

    .GROUP
    CodeQuality

    .CONFIGURATION
    Set `Tasks.PSScriptAnalyzer.IncludeTests` to control whether files under
    `Tests` are analyzed. The default is `$true`.

    `Tasks.PSScriptAnalyzer.Exclude` excludes matching files from this task.

    PSScriptAnalyzer settings can be supplied at the build root in
    `PSScriptAnalyzerSettings.psd1`.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        Tasks          = @{
            PSScriptAnalyzer = @{
                IncludeTests = $false
                Exclude      = @('Tests/Assets/*.ps1')
            }
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
Add-BuildTask -Name PSScriptAnalyzer -Jobs SetVariables, { Invoke-PlumberPSScriptAnalyzer }
