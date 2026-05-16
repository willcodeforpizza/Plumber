<#
    .SYNOPSIS
    Runs module convention validation.

    .DESCRIPTION
    Runs validation tasks that check module manifest, exported functions,
    public function prefixes, function files, naming, TODO comments, and
    function help.

    .INCLUDES
    Manifest
    PublicFunctions
    PublicFunctionPrefix
    FunctionFiles
    Naming
    ToDo
    Help

    .RUN
    ```powershell
    Invoke-Plumber -Task ModuleConventions
    ```
#>
Add-BuildTask -Name ModuleConventions -Jobs $script:PlumberTaskJobs.ModuleConventions
