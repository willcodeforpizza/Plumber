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
