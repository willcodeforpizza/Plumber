<#
    .SYNOPSIS
    Validates PowerShell source files do not exceed the configured line length.

    .DESCRIPTION
    Checks `.ps1`, `.psm1`, and `.psd1` files under the build root and fails
    when a line is longer than the configured maximum.

    .GROUP
    CodeQuality

    .CONFIGURATION
    `Tasks.LineLength.MaxLength` controls the maximum allowed line length. The
    default is `115`.

    `Tasks.LineLength.Exclude` excludes matching files from this task.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        Tasks          = @{
            LineLength = @{
                MaxLength = 80
                Exclude   = @('Tests/Assets/LongLines.ps1')
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task LineLength
    ```

    .PASS
    ```powershell
    $name = 'LineLength'
    "Task: $name"
    ```

    .FAIL
    ```powershell
    $line = '<more than configured maximum characters on one physical line>'
    ```
#>
Add-BuildTask -Name LineLength -Jobs {
    # Scope can be lost when running Plumber on Plumber multiple times
    if (-not (Get-Command Get-PlumberTaskFile -ErrorAction SilentlyContinue)) {
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Test-PlumberTaskPathExcluded.ps1')
        . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberTaskFile.ps1')
    }

    $extensions = '.ps1', '.psm1', '.psd1'
    $files = Get-PlumberTaskFile -Task LineLength -Extension $extensions

    $failures = foreach ($file in $files) {
        $lineNumber = 0
        foreach ($line in Get-Content $file.FullName) {
            $lineNumber++
            if ($line.Length -gt $script:PlumberConfig.Tasks.LineLength.MaxLength) {
                (
                    "$($file.Name):$lineNumber - " +
                    "Line is $($line.Length) characters " +
                    ">$($script:PlumberConfig.Tasks.LineLength.MaxLength)"
                )
            }
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
