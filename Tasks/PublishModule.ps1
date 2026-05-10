<#
    .SYNOPSIS
    Publishes Plumber to PowerShell Gallery.

    .DESCRIPTION
    This is an internal build task for Plumber, and not part of the core task list.

    Builds a clean module folder with `BuildModule` and publishes `out/Plumber`
    using `Publish-PSResource`.

    The PowerShell Gallery API key is read from `PSGALLERY_API_KEY`.

    By default this task runs with `-WhatIf`. Set `PLUMBER_PUBLISH_CONFIRM` to
    `true` to publish for real.

    .RUN
    ```powershell
    $env:PSGALLERY_API_KEY = '<api-key>'
    Invoke-Build -File ./Plumber.build.ps1 -Task PublishModule
    ```
#>
Add-BuildTask -Name PublishModule -Jobs BuildModule, {
    $publishPath = Join-Path $BuildRoot 'out/Plumber'
    $apiKey = $env:PSGALLERY_API_KEY
    if (-not $apiKey) {
        Write-Error 'Set PSGALLERY_API_KEY before running PublishModule.'
        return
    }

    if (-not (Get-Command Publish-PSResource -ErrorAction SilentlyContinue)) {
        Write-Error 'Publish-PSResource is required. Install Microsoft.PowerShell.PSResourceGet.'
        return
    }

    $publishSplat = @{
        Path       = $publishPath
        Repository = 'PSGallery'
        ApiKey     = $apiKey
        Verbose    = $true
        WhatIf     = $env:PLUMBER_PUBLISH_CONFIRM -ne 'true'
    }

    Publish-PSResource @publishSplat
}
