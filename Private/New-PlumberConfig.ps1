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
        ExcludeDirectories   = @()
        Tasks                = @{
            Local                = @()
            CodeQuality          = @{
                RunWhen = 'Always'
            }
            ReleaseHygiene       = @{
                RunWhen = 'Always'
            }
            Content              = @{
                RunWhen = 'Always'
            }
            ModuleConventions    = @{
                RunWhen = 'Always'
            }
            Backticks            = @{
                RunWhen = 'Always'
                Exclude     = @()
            }
            CodeCoverage         = @{
                RunWhen = 'Always'
                Minimum     = 75
            }
            Help                 = @{
                RunWhen         = 'Always'
                PrivateSynopsisOnly = $true
            }
            JSON                 = @{
                RunWhen = 'Always'
                Exclude     = @()
            }
            JSONSchema           = @{
                RunWhen = 'Always'
                Exclude     = @()
                Schemas     = @()
            }
            LineLength           = @{
                RunWhen = 'Always'
                Exclude     = @()
                MaxLength   = 115
            }
            PathSeparator        = @{
                RunWhen = 'Always'
                Exclude     = @()
            }
            ModuleVersion        = @{
                RunWhen       = 'Always'
                IncludePrerelease = $false
                Remote            = 'origin'
                Source            = 'PSGallery'
            }
            ChangelogUpdated      = @{
                RunWhen = 'Always'
            }
            PesterIntegration    = @{
                RunWhen  = 'Always'
                StreamOutput = $true
            }
            PesterUnit           = @{
                RunWhen  = 'Always'
                StreamOutput = $true
            }
            PSScriptAnalyzer     = @{
                RunWhen  = 'Always'
                Exclude      = @()
                IncludeTests = $true
            }
            Manifest             = @{
                RunWhen = 'Always'
            }
            PublicFunctions       = @{
                RunWhen = 'Always'
            }
            PublicFunctionPrefix = @{
                RunWhen = 'Always'
                Exclusions  = @()
                Prefix      = $null
            }
            FunctionFiles         = @{
                RunWhen = 'Always'
                Exclude     = @()
            }
            Naming                = @{
                RunWhen = 'Always'
            }
            ToDo                 = @{
                RunWhen = 'Always'
                Exclude     = @()
            }
            YAML                 = @{
                RunWhen = 'Always'
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
