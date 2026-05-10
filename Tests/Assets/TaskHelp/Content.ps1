<#
    .SYNOPSIS
    Runs content validation tasks.

    .DESCRIPTION
    Runs validation tasks that check repository content files.

    .INCLUDES
    JSON
    JSONSchema
    YAML

    .RUN
    ```powershell
    Invoke-Plumber -Task Content
    ```
#>
Add-BuildTask -Name Content -Jobs {}
