function Invoke-PlumberJSON {
    <#
        .SYNOPSIS
        Runs the JSON task body.
    #>
    [CmdletBinding()]
    param ()

    $jsonFiles = Get-PlumberTaskFile -Task JSON -Extension '.json'
    if (-not $jsonFiles) {
        Write-Build Yellow 'No JSON files found'
        return
    }

    $failures = @()
    foreach ($jsonFile in $jsonFiles) {
        try {
            Get-Content $jsonFile.FullName -Raw -ErrorAction Stop |
                ConvertFrom-Json -ErrorAction Stop |
                ConvertTo-Json -ErrorAction Stop | Out-Null
        }
        catch {
            # Write-Error per file would terminate the loop under
            # Invoke-Build's ErrorActionPreference Stop; collect instead.
            $failures += "Invalid JSON in $($jsonFile.FullName): $($_.Exception.Message)"
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
