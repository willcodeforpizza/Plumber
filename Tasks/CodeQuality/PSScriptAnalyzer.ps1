<#
    .SYNOPSIS
    Validates PSScriptAnalyzer passes
#>
Add-BuildTask -Name PSScriptAnalyzer -Jobs SetVariables, {
    $scriptFiles = Get-ChildItem $BuildRoot -File -Recurse |
        Where-Object {$_.Extension -in '.ps1', '.psd1', '.psm1'}
    $settingsPath = Join-Path $BuildRoot 'PSScriptAnalyzerSettings.psd1'
    $settingsSplat = if (Test-Path $settingsPath) { @{ Settings = $settingsPath } } else { @{} }
    $scriptFailures = $scriptFiles |
    ForEach-Object { Invoke-ScriptAnalyzer $_.FullName @settingsSplat }
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
