<#
    .SYNOPSIS
    Validates public functions use the configured command prefix.

    .DESCRIPTION
    Checks files under `Public` and fails when a public function name does not
    use the configured noun prefix. The default prefix is the module name.

    .GROUP
    ModuleConventions

    .CONFIGURATION
    `PublicFunctionPrefix` overrides the expected prefix. The default is the
    configured module name.

    `PublicFunctionPrefixExclusions` excludes exact public function names from
    this check.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        PublicFunctionPrefix           = 'My'
        PublicFunctionPrefixExclusions = @('New-Thing')
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task PublicFunctionPrefix
    ```

    .PASS
    ```powershell
    function Get-MyThing {}
    ```

    .FAIL
    ```powershell
    function Get-Thing {}
    ```
#>
Add-BuildTask -Name PublicFunctionPrefix -Jobs SetVariables, {
    $prefix = if ($script:PlumberConfig.PublicFunctionPrefix) {
        $script:PlumberConfig.PublicFunctionPrefix
    } else {
        $script:moduleName
    }
    $exclusions = @($script:PlumberConfig.PublicFunctionPrefixExclusions)
    $publicRoot = Join-Path $BuildRoot 'Public'
    if (-not (Test-Path $publicRoot)) {
        return
    }

    $failures = foreach ($publicFile in Get-ChildItem $publicRoot -File -Filter '*.ps1') {
        $functionName = $publicFile.BaseName
        if ($functionName -in $exclusions) {
            continue
        }

        $commandParts = $functionName -split '-', 2
        if ($commandParts.Count -ne 2 -or -not ($commandParts[1] -clike "$prefix*")) {
            "$functionName does not use public function prefix '$prefix'"
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
