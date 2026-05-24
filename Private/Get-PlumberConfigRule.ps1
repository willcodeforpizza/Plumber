function Get-PlumberConfigRule {
    <#
        .SYNOPSIS
        Gets the Plumber config validation rule map.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()

    $runWhenRule = @{Validate = 'enum'; Values = @('Always', 'OnRelease', 'Never')}

    @{
        ModuleManifest                          = @{Validate = 'string'; Nullable = $true}
        DiffBase                                = @{Validate = 'string'; Nullable = $true}
        FileScope                               = @{Validate = 'enum'; Values = @('All', 'Changed')}
        IncludeModuleFolders                    = @{Validate = 'string-array'}
        BuildRoot                               = @{Validate = 'string'}
        'Tasks.Local'                           = @{Validate = 'string-array'}
        'Tasks.CodeQuality.RunWhen'             = $runWhenRule
        'Tasks.ReleaseHygiene.RunWhen'          = $runWhenRule
        'Tasks.Content.RunWhen'                 = $runWhenRule
        'Tasks.ModuleConventions.RunWhen'       = $runWhenRule
        'Tasks.Backticks.RunWhen'           = $runWhenRule
        'Tasks.Backticks.Exclude'               = @{Validate = 'string-array'}
        'Tasks.CodeCoverage.RunWhen'        = $runWhenRule
        'Tasks.CodeCoverage.Minimum'            = @{Validate = 'integer'; Min = 0; Max = 100}
        'Tasks.Help.RunWhen'                = $runWhenRule
        'Tasks.Help.PrivateSynopsisOnly'        = @{Validate = 'boolean'}
        'Tasks.JSON.RunWhen'                = $runWhenRule
        'Tasks.JSON.Exclude'                    = @{Validate = 'string-array'}
        'Tasks.JSONSchema.RunWhen'          = $runWhenRule
        'Tasks.JSONSchema.Exclude'              = @{Validate = 'string-array'}
        'Tasks.JSONSchema.Schemas'              = @{
            Validate = 'object-array'
            ItemRule = @{
                Path   = @{Validate = 'string'}
                Schema = @{Validate = 'string'}
            }
        }
        'Tasks.LineLength.RunWhen'          = $runWhenRule
        'Tasks.LineLength.Exclude'              = @{Validate = 'string-array'}
        'Tasks.LineLength.MaxLength'            = @{
            Validate = 'integer'
            Min      = 1
            Max      = 10000
        }
        'Tasks.PathSeparator.RunWhen'       = $runWhenRule
        'Tasks.PathSeparator.Exclude'           = @{Validate = 'string-array'}
        'Tasks.ModuleVersion.RunWhen'       = $runWhenRule
        'Tasks.ModuleVersion.IncludePrerelease' = @{Validate = 'boolean'}
        'Tasks.ModuleVersion.Remote'            = @{Validate = 'string'}
        'Tasks.ModuleVersion.Source'            = @{
            Validate = 'enum'
            Values   = @('PSGallery', 'GitTag')
        }
        'Tasks.ChangelogUpdated.RunWhen'    = $runWhenRule
        'Tasks.PesterIntegration.RunWhen'   = $runWhenRule
        'Tasks.PesterIntegration.StreamOutput'  = @{Validate = 'boolean'}
        'Tasks.PesterUnit.RunWhen'          = $runWhenRule
        'Tasks.PesterUnit.StreamOutput'         = @{Validate = 'boolean'}
        'Tasks.PSScriptAnalyzer.RunWhen'    = $runWhenRule
        'Tasks.PSScriptAnalyzer.Exclude'        = @{Validate = 'string-array'}
        'Tasks.PSScriptAnalyzer.IncludeTests'   = @{Validate = 'boolean'}
        'Tasks.Manifest.RunWhen'            = $runWhenRule
        'Tasks.PublicFunctions.RunWhen'     = $runWhenRule
        'Tasks.PublicFunctionPrefix.RunWhen' = $runWhenRule
        'Tasks.PublicFunctionPrefix.Exclusions' = @{Validate = 'string-array'}
        'Tasks.PublicFunctionPrefix.Prefix'     = @{Validate = 'string'; Nullable = $true}
        'Tasks.FunctionFiles.RunWhen'       = $runWhenRule
        'Tasks.FunctionFiles.Exclude'           = @{Validate = 'string-array'}
        'Tasks.Naming.RunWhen'              = $runWhenRule
        'Tasks.ToDo.RunWhen'                = $runWhenRule
        'Tasks.ToDo.Exclude'                    = @{Validate = 'string-array'}
        'Tasks.YAML.RunWhen'                = $runWhenRule
        'Tasks.YAML.Exclude'                    = @{Validate = 'string-array'}
    }
}
