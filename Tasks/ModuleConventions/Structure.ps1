<#
    .SYNOPSIS
    Validates content files are not stored in the root of the module.

    .DESCRIPTION
    Fails when `.json`, `.yml`, or `.yaml` files are found in the build root.
    Content files should live under `Resource`.

    .GROUP
    ModuleConventions

    .CONFIGURATION
    None.

    .RUN
    ```powershell
    Invoke-Plumber -Task Structure
    ```

    .PASS
    ```text
    Resource/config.json
    ```

    .FAIL
    ```text
    config.json
    ```
#>
Add-BuildTask -Name Structure -Jobs {
    $misplacedContent = Get-ChildItem $BuildRoot -File |
        Where-Object {$_.Extension -in '.json', '.yml', '.yaml'}

    if ($misplacedContent) {
        $fileList = $misplacedContent.Name -join ', '
        Write-Error "Content files should be in Resource folder: $fileList"
    }
}
