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
Add-BuildTask -Name Help -Jobs SetVariables, {
    $publicRoot = Join-Path $BuildRoot 'Public'
    $functionRoots = @(
        @{
            Path            = $publicRoot
            RequireFullHelp = $true
        }
    )
    $functionRoots += foreach ($moduleFolder in $script:moduleFolders) {
        if ($moduleFolder.Equals($publicRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        @{
            Path            = $moduleFolder
            RequireFullHelp = -not $script:PlumberConfig.Tasks.Help.PrivateSynopsisOnly
        }
    }

    $failures = foreach ($functionRoot in $functionRoots) {
        if (-not (Test-Path $functionRoot.Path)) {
            continue
        }

        foreach ($file in Get-ChildItem $functionRoot.Path -File -Filter '*.ps1') {
            $help = Get-PlumberFunctionHelp -Path $file.FullName
            Test-PlumberFunctionHelp -Help $help -RequireFullHelp:$functionRoot.RequireFullHelp
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
