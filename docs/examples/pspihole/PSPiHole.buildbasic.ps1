$script:moduleRoot = $PSScriptRoot

Add-BuildTask -Name Validate -Jobs Test, Analyze

Add-BuildTask -Name Test -Jobs {
    $testPath = (Resolve-Path (Join-Path $script:moduleRoot 'Tests')).Path
    Invoke-Pester -Path $testPath -EnableExit
}

Add-BuildTask -Name Analyze -Jobs {
    $findings = Invoke-ScriptAnalyzer $script:moduleRoot -IncludeDefaultRules -Recurse

    if ($findings) {
        $findings | Format-Table | Out-String
        Write-Error 'PSSA errors found'
    }
}
