<#
    .SYNOPSIS
    Publishes module to PowerShell Gallery.

    .DESCRIPTION
    Builds a clean module folder with `BuildModule` and publishes it with
    `Publish-PSResource`.

    The PowerShell Gallery API key is read from `PSGALLERY_API_KEY`.

    By default this task runs with `-WhatIf`. Set PSGALLERY_PUBLISH_CONFIRM to
    `true` to publish for real.

    .RUN
    ```powershell
    $env:PSGALLERY_API_KEY = '<api-key>'
    $env:PSGALLERY_PUBLISH_CONFIRM = 'true'

    # standalone
    Invoke-Build -File ./Tasks/PublishModule.ps1

    # via the entry point (supports CLI overrides)
    Invoke-Build -File ./Tasks/Publish.ps1 PublishModule
    ```
#>
if ($script:_loadedPublishModule) { return }
$script:_loadedPublishModule = $true

Add-BuildTask -Name PublishModule -Jobs BuildModule, {
    $apiKey = $env:PSGALLERY_API_KEY
    $publishConfirmed = $env:PSGALLERY_PUBLISH_CONFIRM -eq 'true'
    if ($publishConfirmed -and -not $apiKey) {
        Write-Error 'Set PSGALLERY_API_KEY before running PublishModule.'
        return
    }

    if (-not (Get-Command Publish-PSResource -ErrorAction SilentlyContinue)) {
        Write-Error 'Publish-PSResource is required. Install Microsoft.PowerShell.PSResourceGet.'
        return
    }

    $publishSplat = @{
        Path       = $ModuleOutputRoot
        Repository = 'PSGallery'
        Verbose    = $true
        WhatIf     = -not $publishConfirmed
    }
    if ($apiKey) {
        $publishSplat.ApiKey = $apiKey
    }

    Publish-PSResource @publishSplat
}

. (Join-Path $PSScriptRoot 'BuildModule.ps1')
