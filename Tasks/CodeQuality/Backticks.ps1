<#
    .SYNOPSIS
    Validates PowerShell files do not use line-continuation backticks.

    .DESCRIPTION
    Checks `.ps1`, `.psm1`, and `.psd1` files and fails when a backtick is used
    as the final non-whitespace character on a line.

    .GROUP
    CodeQuality

    .CONFIGURATION
    `Tasks.Backticks.Exclude` excludes matching files from this task.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        Tasks          = @{
            Backticks = @{
                Exclude = @('Tests/Assets/TaskHelp/*.ps1')
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task Backticks
    ```

    .PASS
    ```powershell
    Get-Foo -DoBar -AddFizz
    ```

    .FAIL
    ```text
    A PowerShell line whose final non-whitespace character is a backtick.
    ```
#>
Add-BuildTask -Name Backticks -Jobs {
    # Scope can be lost when running Plumber on Plumber multiple times
    if (-not (Get-Command Get-PlumberTaskFile -ErrorAction SilentlyContinue)) {
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Test-PlumberTaskPathExcluded.ps1')
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberTaskFile.ps1')
    }

    $powershellFiles = Get-PlumberTaskFile -Task Backticks -Extension '.ps1', '.psd1', '.psm1'

    $failures = foreach ($file in $powershellFiles) {
        $lineNumber = 0
        foreach ($line in Get-Content $file.FullName) {
            $lineNumber++
            if ($line -match '(?<!`)`\s*$') {
                "$($file.Name):$lineNumber - Line-continuation backtick found"
            }
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
