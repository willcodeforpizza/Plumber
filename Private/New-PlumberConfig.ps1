function New-PlumberConfig {
    <#
        .SYNOPSIS
        Creates Plumber task loader configuration.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Creates an in-memory configuration object only.'
    )]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [hashtable]
        $Config = @{}
    )

    $defaults = @{
        ModuleManifest          = $null
        CoverageMinimum         = 75
        DiffBase                = $null
        FileScope               = 'All'
        IncludeTestsInPssa      = $true
        JsonSchemas             = @()
        MaxLineLength           = 115
        PrivateHelpSynopsisOnly = $true
        ExcludeTasks            = @()
        ExcludePaths            = @{}
        LocalTasks              = @()
    }

    $plumberConfig = $defaults.Clone()
    foreach ($key in $Config.Keys) {
        $plumberConfig[$key] = $Config[$key]
    }

    if (-not $plumberConfig.ExcludeTasks) {
        $plumberConfig.ExcludeTasks = @()
    }
    if (-not $plumberConfig.ExcludePaths) {
        $plumberConfig.ExcludePaths = @{}
    }
    if (-not $plumberConfig.LocalTasks) {
        $plumberConfig.LocalTasks = @()
    }
    if (Get-Variable -Name BuildRoot -ErrorAction SilentlyContinue) {
        $plumberConfig.BuildRoot = $BuildRoot
    }

    $plumberConfig
}
