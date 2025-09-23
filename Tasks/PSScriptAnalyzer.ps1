<#
    .SYNOPSIS
    Validates PSScriptAnalyzer passes
#>
task -Name PSScriptAnalyzer -Jobs SetVariables, {
    $scriptFailures = $script:moduleFolders |
    ForEach-Object { Invoke-ScriptAnalyzer $_ }
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
