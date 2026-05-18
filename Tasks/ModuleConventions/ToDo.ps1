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
Add-BuildTask -Name ToDo -Jobs { Invoke-PlumberToDo }
