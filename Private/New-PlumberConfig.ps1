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
        ModuleManifest = $null
        DiffBase       = $null
        FileScope      = 'All'
        Tasks          = @{
            Exclude              = @()
            Local                = @()
            Backticks            = @{
                Exclude = @()
            }
            CodeCoverage         = @{
                Minimum = 75
            }
            Help                 = @{
                PrivateSynopsisOnly = $true
            }
            JSON                 = @{
                Exclude = @()
            }
            JSONSchema           = @{
                Exclude = @()
                Schemas = @()
            }
            LineLength           = @{
                Exclude   = @()
                MaxLength = 115
            }
            PathSeparator        = @{
                Exclude = @()
            }
            ModuleVersion        = @{
                IncludePrerelease = $false
                Remote            = 'origin'
                Source            = 'PSGallery'
            }
            PesterIntegration    = @{
                StreamOutput = $true
            }
            PesterUnit           = @{
                StreamOutput = $true
            }
            PSScriptAnalyzer     = @{
                Exclude      = @()
                IncludeTests = $true
            }
            PublicFunctionPrefix = @{
                Exclusions = @()
                Prefix     = $null
            }
            ToDo                 = @{
                Exclude = @()
            }
            YAML                 = @{
                Exclude = @()
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
    if (-not $plumberConfig.Tasks.Exclude) {
        $plumberConfig.Tasks.Exclude = @()
    }
    if (-not $plumberConfig.Tasks.Local) {
        $plumberConfig.Tasks.Local = @()
    }
    if (-not $plumberConfig.Tasks.PublicFunctionPrefix.Exclusions) {
        $plumberConfig.Tasks.PublicFunctionPrefix.Exclusions = @()
    }
    $streamVariableSplat = @{
        Name        = 'PlumberStreamPesterOutput'
        Scope       = 'Global'
        ErrorAction = 'SilentlyContinue'
    }
    $streamPesterOutputVariable = Get-Variable @streamVariableSplat
    if ($null -ne $streamPesterOutputVariable) {
        $streamPesterOutput = [bool](
            Get-Variable -Name PlumberStreamPesterOutput -Scope Global -ValueOnly
        )
        $plumberConfig.Tasks.PesterIntegration.StreamOutput = $streamPesterOutput
        $plumberConfig.Tasks.PesterUnit.StreamOutput = $streamPesterOutput
    }
    if (Get-Variable -Name BuildRoot -ErrorAction SilentlyContinue) {
        $plumberConfig.BuildRoot = $BuildRoot
    }

    $plumberConfig
}
