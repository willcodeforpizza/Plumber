<#
    .SYNOPSIS
    Validates JSON files can be parsed.

    .DESCRIPTION
    Finds `.json` files directly under the `Resource` directory and verifies
    that each file can be parsed from JSON and serialized back to JSON.

    .GROUP
    Content

    .CONFIGURATION
    `ExcludePaths.JSON` excludes matching files from this task.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        ExcludePaths   = @{
            JSON = @('Resource/generated.json')
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
    # Scope can be lost when running Plumber on Plumber multiple times
    if (-not (Get-Command Get-PlumberTaskFile -ErrorAction SilentlyContinue)) {
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Test-PlumberTaskPathExcluded.ps1')
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberTaskFile.ps1')
    }

    $resourcePath = Join-Path $BuildRoot 'Resource'
    $jsonFiles = Get-PlumberTaskFile -Task JSON -Extension '.json' -Path Resource |
        Where-Object {
            $_.DirectoryName.Equals(
                $resourcePath,
                [System.StringComparison]::OrdinalIgnoreCase
            )
        }
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
