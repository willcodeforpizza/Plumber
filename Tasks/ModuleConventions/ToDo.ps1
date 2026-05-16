<#
    .SYNOPSIS
    Validates no TODO comments are left in files.

    .DESCRIPTION
    Checks files under the build root and fails when a code comment begins with
    `TODO`.

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
    A code comment begins with the TODO marker.
    ```
#>
Add-BuildTask -Name ToDo -Jobs {
    $extensions = '.ps1', '.psm1', '.psd1'
    $toDos = Get-PlumberTaskFile -Task ToDo -Extension $extensions |
        Where-Object {$_.Name -ne 'ToDo.ps1'} |
        ForEach-Object {
        $file = $_
        Get-Content $_.FullName | Where-Object {$_ -match '^\s*#\s*TODO\b'} | ForEach-Object {
            "$($file.Name): $(($_ -replace '^\s*#\s*TODO:?\s*', '').Trim())"
        }
    }
    if ($toDos) {
        Write-Error ($toDos -join (', ' + [Environment]::NewLine))
    }
}
