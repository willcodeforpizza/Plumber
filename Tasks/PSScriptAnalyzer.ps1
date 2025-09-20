task PSScriptAnalyzer {
    $scriptFailures = $script:moduleFolders | ForEach-Object {Invoke-ScriptAnalyzer $_}
    $failures = foreach ($failure in $scriptFailures) {
        (
            "$($failure.ScriptName):$($failure.Line) - " + 
            "$($failure.RuleName) - $($failure.Message)"
        )
    }
    Write-Error ($failures -join  (', ' + [Environment]::NewLine))
}
