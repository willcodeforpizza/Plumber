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
        $Config = @{},

        [string]
        $BuildRoot
    )

    $defaults = @{
        ModuleManifest       = $null
        DiffBase             = $null
        FileScope            = 'All'
        IncludeModuleFolders = @()
        Tasks                = @{
            Local                = @()
            Backticks            = @{
                EnforceWhen = 'Always'
                Exclude     = @()
            }
            CodeCoverage         = @{
                EnforceWhen = 'Always'
                Minimum     = 75
            }
            Help                 = @{
                EnforceWhen         = 'Always'
                PrivateSynopsisOnly = $true
            }
            JSON                 = @{
                EnforceWhen = 'Always'
                Exclude     = @()
            }
            JSONSchema           = @{
                EnforceWhen = 'Always'
                Exclude     = @()
                Schemas     = @()
            }
            LineLength           = @{
                EnforceWhen = 'Always'
                Exclude     = @()
                MaxLength   = 115
            }
            PathSeparator        = @{
                EnforceWhen = 'Always'
                Exclude     = @()
            }
            ModuleVersion        = @{
                EnforceWhen       = 'Always'
                IncludePrerelease = $false
                Remote            = 'origin'
                Source            = 'PSGallery'
            }
            ChangelogUpdated      = @{
                EnforceWhen = 'Always'
            }
            PesterIntegration    = @{
                EnforceWhen  = 'Always'
                StreamOutput = $true
            }
            PesterUnit           = @{
                EnforceWhen  = 'Always'
                StreamOutput = $true
            }
            PSScriptAnalyzer     = @{
                EnforceWhen  = 'Always'
                Exclude      = @()
                IncludeTests = $true
            }
            Manifest             = @{
                EnforceWhen = 'Always'
            }
            PublicFunctions       = @{
                EnforceWhen = 'Always'
            }
            PublicFunctionPrefix = @{
                EnforceWhen = 'Always'
                Exclusions  = @()
                Prefix      = $null
            }
            FunctionFiles         = @{
                EnforceWhen = 'Always'
                Exclude     = @()
            }
            Naming                = @{
                EnforceWhen = 'Always'
            }
            ToDo                 = @{
                EnforceWhen = 'Always'
                Exclude     = @()
            }
            YAML                 = @{
                EnforceWhen = 'Always'
                Exclude     = @()
            }
        }
    }

    $plumberConfig = Copy-PlumberHashtable -InputObject $defaults
    foreach ($key in $Config.Keys) {
        if ($key -eq 'Tasks') {
            foreach ($taskKey in $Config.Tasks.Keys) {
                if (
                    $plumberConfig.Tasks.ContainsKey($taskKey) -and
                    $plumberConfig.Tasks[$taskKey] -is [hashtable] -and
                    $Config.Tasks[$taskKey] -is [hashtable]
                ) {
                    foreach ($settingKey in $Config.Tasks[$taskKey].Keys) {
                        $plumberConfig.Tasks[$taskKey][$settingKey] = $Config.Tasks[$taskKey][$settingKey]
                    }
                } else {
                    $plumberConfig.Tasks[$taskKey] = $Config.Tasks[$taskKey]
                }
            }
        } else {
            $plumberConfig[$key] = $Config[$key]
        }
    }

    if (-not $plumberConfig.Tasks) {
        $plumberConfig.Tasks = @{}
    }
    if (-not $plumberConfig.Tasks.Local) {
        $plumberConfig.Tasks.Local = @()
    }
    if (-not $plumberConfig.IncludeModuleFolders) {
        $plumberConfig.IncludeModuleFolders = @()
    }
    if (-not $plumberConfig.Tasks.PublicFunctionPrefix.Exclusions) {
        $plumberConfig.Tasks.PublicFunctionPrefix.Exclusions = @()
    }
    $streamPesterOutput = Get-PlumberStreamPesterOutput
    if ($null -ne $streamPesterOutput) {
        $plumberConfig.Tasks.PesterIntegration.StreamOutput = $streamPesterOutput
        $plumberConfig.Tasks.PesterUnit.StreamOutput = $streamPesterOutput
    }
    if ($BuildRoot) {
        $plumberConfig.BuildRoot = $BuildRoot
    }

    $plumberConfig
}
