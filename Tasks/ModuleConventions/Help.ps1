<#
    .SYNOPSIS
    Validates public and private function help.

    .DESCRIPTION
    Validates comment-based help on functions in module source folders. Public
    functions require a synopsis, description, example and parameter help.
    Non-public module functions require synopsis-only help unless configured
    otherwise.

    .GROUP
    ModuleConventions

    .CONFIGURATION
    `Tasks.Help.PrivateSynopsisOnly` controls whether private functions require
    only a synopsis or full help. The default is `$true`.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
        Tasks          = @{
            Help = @{
                PrivateSynopsisOnly = $false
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task Help
    ```

    .PASS
    ```text
    Public/Get-Thing.ps1 contains comment-based help with a SYNOPSIS section.
    ```

    .FAIL
    ```text
    Public/Get-Thing.ps1 contains a function with no comment-based help.
    ```
#>
Add-BuildTask -Name Help -Jobs SetVariables, { Invoke-PlumberHelp }
