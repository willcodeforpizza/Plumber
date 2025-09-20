task Changelog {
    $changelog = Get-Content C:\gh\Plumber\changelog.md #$BuildRoot
    $latestLine = $changelog | 
        Where-Object {$_ -match '^## [0-9]'} | 
        Select-Object -First 1

    $changelogVersion = [version]($latestLine -replace '## ')
    $psd1Version = $script:psd1.ModuleVersion

    if ($psd1Version -ne $changelogVersion) {
        Write-Error (
            'Changelog might be out of date. ' +
            "PSD1 version $psd1Version " + 
            "changelog version $changelogVersion"
        )
    }
}