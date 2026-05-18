<#
    .SYNOPSIS
    Validates the changelog has been updated.

    .DESCRIPTION
    Compares the latest version heading in `CHANGELOG.md` with the configured
    module manifest version and fails when they do not match.

    .GROUP
    ReleaseHygiene

    .CONFIGURATION
    `ModuleManifest` controls which module manifest supplies `ModuleVersion`.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task ChangelogUpdated
    ```

    .PASS
    ```markdown
    ## 1.2.3
    ```

    .FAIL
    ```markdown
    ## 1.2.2
    ```
#>
Add-BuildTask -Name ChangelogUpdated -Jobs SetVariables, { Invoke-PlumberChangelogUpdated }
