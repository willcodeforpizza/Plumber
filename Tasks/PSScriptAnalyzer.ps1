<#
    .SYNOPSIS
    Validates PSScriptAnalyzer passes
#>
task -Name PSScriptAnalyzer -Jobs SetVariables, {
    $settingsPath = Join-Path $BuildRoot 'PSScriptAnalyzerSettings.psd1'
    $settingsSplat = if (Test-Path $settingsPath) { @{ Settings = $settingsPath } } else { @{} }
    $scriptFailures = $script:moduleFolders |
    ForEach-Object { Invoke-ScriptAnalyzer $_ @settingsSplat }
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
