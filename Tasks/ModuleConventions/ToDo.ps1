<#
    .SYNOPSIS
    Validates no TODO comments are left in files.

    .DESCRIPTION
    Checks `.ps1`, `.psm1`, and `.psd1` files and fails when a line comment
    contains a TODO marker. Detection is AST-aware so TODO text inside string
    literals or block comments is not flagged. Both leading-line TODOs
    (`# TODO: fix this`) and inline TODOs after code on the same line
    (`$x = 1 # TODO: fix this`) are reported.

    .GROUP
    ModuleConventions

    .CONFIGURATION
    `Tasks.ToDo.Exclude` excludes matching files from this task.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        Tasks          = @{
            ToDo = @{
                Exclude = @('docs/examples/*.ps1')
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task ToDo
    ```

    .PASS
    ```powershell
    # Documents why the next command exists.
    ```

    .FAIL
    ```text
    A line comment contains the TODO marker.
    ```
#>
Add-BuildTask -Name ToDo -Jobs {
    $extensions = '.ps1', '.psm1', '.psd1'
    $taskFiles = Get-PlumberTaskFile -Task ToDo -Extension $extensions |
        Where-Object {$_.Name -ne 'ToDo.ps1'}

    $toDos = foreach ($file in $taskFiles) {
        try {
            $hits = Get-PlumberToDoComment -Path $file.FullName
        } catch {
            "$($file.Name): could not parse file: $($_.Exception.Message)"
            continue
        }
        foreach ($hit in $hits) {
            "$($file.Name):$($hit.Line) - $($hit.Message)".TrimEnd(' -')
        }
    }

    if ($toDos) {
        Write-Error ($toDos -join (', ' + [Environment]::NewLine))
    }
}
