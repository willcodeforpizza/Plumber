function Get-PlumberConfigRule {
    <#
        .SYNOPSIS
        Gets the Plumber config validation rule map.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()

    @{
        ModuleManifest                          = @{Validate = 'string'; Nullable = $true}
        DiffBase                                = @{Validate = 'string'; Nullable = $true}
        FileScope                               = @{Validate = 'enum'; Values = @('All', 'Changed')}
        IncludeModuleFolders                    = @{Validate = 'string-array'}
        BuildRoot                               = @{Validate = 'string'}
        'Tasks.Exclude'                         = @{Validate = 'string-array'}
        'Tasks.Local'                           = @{Validate = 'string-array'}
        'Tasks.Backticks.Exclude'               = @{Validate = 'string-array'}
        'Tasks.CodeCoverage.Minimum'            = @{Validate = 'integer'; Min = 0; Max = 100}
        'Tasks.Help.PrivateSynopsisOnly'        = @{Validate = 'boolean'}
        'Tasks.JSON.Exclude'                    = @{Validate = 'string-array'}
        'Tasks.JSONSchema.Exclude'              = @{Validate = 'string-array'}
        'Tasks.JSONSchema.Schemas'              = @{
            Validate = 'object-array'
            ItemRule = @{
                Path   = @{Validate = 'string'}
                Schema = @{Validate = 'string'}
            }
        }
        'Tasks.LineLength.Exclude'              = @{Validate = 'string-array'}
        'Tasks.LineLength.MaxLength'            = @{
            Validate = 'integer'
            Min      = 1
            Max      = 10000
        }
        'Tasks.PathSeparator.Exclude'           = @{Validate = 'string-array'}
        'Tasks.ModuleVersion.IncludePrerelease' = @{Validate = 'boolean'}
        'Tasks.ModuleVersion.Remote'            = @{Validate = 'string'}
        'Tasks.ModuleVersion.Source'            = @{
            Validate = 'enum'
            Values   = @('PSGallery', 'GitTag')
        }
        'Tasks.PesterIntegration.StreamOutput'  = @{Validate = 'boolean'}
        'Tasks.PesterUnit.StreamOutput'         = @{Validate = 'boolean'}
        'Tasks.PSScriptAnalyzer.Exclude'        = @{Validate = 'string-array'}
        'Tasks.PSScriptAnalyzer.IncludeTests'   = @{Validate = 'boolean'}
        'Tasks.PublicFunctionPrefix.Exclusions' = @{Validate = 'string-array'}
        'Tasks.PublicFunctionPrefix.Prefix'     = @{Validate = 'string'; Nullable = $true}
        'Tasks.ToDo.Exclude'                    = @{Validate = 'string-array'}
        'Tasks.YAML.Exclude'                    = @{Validate = 'string-array'}
    }
}
