<#
    .SYNOPSIS
    Validates JSON files can be parsed.

    .DESCRIPTION
    Finds `.json` files under the build root and verifies that each file can be
    parsed from JSON and serialized back to JSON.

    .GROUP
    Content

    .CONFIGURATION
    `Tasks.JSON.Exclude` excludes matching files from this task.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        Tasks          = @{
            JSON = @{
                Exclude = @('Resource/generated.json')
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task JSON
    ```

    .PASS
    ```json
    {
      "name": "Plumber",
      "enabled": true
    }
    ```

    .FAIL
    ```json
    {
      "name": "Plumber",
      "enabled": true
    ```
#>
Add-BuildTask -Name JSON -Jobs {
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
