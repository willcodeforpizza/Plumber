<#
    .SYNOPSIS
    Validates JSON files can be parsed
#>
Add-BuildTask -Name JSON -Jobs {
    $jsonFiles = Get-ChildItem "$BuildRoot\Resource" -File -Filter '*.json' -ErrorAction SilentlyContinue
    if (-not $jsonFiles) {
        Write-Build Yellow 'No JSON files found'
        return
    }

    foreach ($jsonFile in $jsonFiles) {
        try {
            Get-Content $jsonFile.FullName -Raw -ErrorAction Stop |
                ConvertFrom-Json -ErrorAction Stop |
                ConvertTo-Json -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Error "Invalid JSON in $($jsonFile.FullName): $($_.Exception.Message)"
        }
    }
}
