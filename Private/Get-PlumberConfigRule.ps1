function Get-PlumberConfigRule {
    <#
        .SYNOPSIS
        Gets the Plumber config validation rule map.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()

    $enforceWhenRule = @{Validate = 'enum'; Values = @('Always', 'OnRelease', 'Never')}

    @{
        ModuleManifest                          = @{Validate = 'string'; Nullable = $true}
        DiffBase                                = @{Validate = 'string'; Nullable = $true}
        FileScope                               = @{Validate = 'enum'; Values = @('All', 'Changed')}
        IncludeModuleFolders                    = @{Validate = 'string-array'}
        BuildRoot                               = @{Validate = 'string'}
        'Tasks.Local'                           = @{Validate = 'string-array'}
        'Tasks.Backticks.EnforceWhen'           = $enforceWhenRule
        'Tasks.Backticks.Exclude'               = @{Validate = 'string-array'}
        'Tasks.CodeCoverage.EnforceWhen'        = $enforceWhenRule
        'Tasks.CodeCoverage.Minimum'            = @{Validate = 'integer'; Min = 0; Max = 100}
        'Tasks.Help.EnforceWhen'                = $enforceWhenRule
        'Tasks.Help.PrivateSynopsisOnly'        = @{Validate = 'boolean'}
        'Tasks.JSON.EnforceWhen'                = $enforceWhenRule
        'Tasks.JSON.Exclude'                    = @{Validate = 'string-array'}
        'Tasks.JSONSchema.EnforceWhen'          = $enforceWhenRule
        'Tasks.JSONSchema.Exclude'              = @{Validate = 'string-array'}
        'Tasks.JSONSchema.Schemas'              = @{
            Validate = 'object-array'
            ItemRule = @{
                Path   = @{Validate = 'string'}
                Schema = @{Validate = 'string'}
            }
        }
        'Tasks.LineLength.EnforceWhen'          = $enforceWhenRule
        'Tasks.LineLength.Exclude'              = @{Validate = 'string-array'}
        'Tasks.LineLength.MaxLength'            = @{
            Validate = 'integer'
            Min      = 1
            Max      = 10000
        }
        'Tasks.PathSeparator.EnforceWhen'       = $enforceWhenRule
        'Tasks.PathSeparator.Exclude'           = @{Validate = 'string-array'}
        'Tasks.ModuleVersion.EnforceWhen'       = $enforceWhenRule
        'Tasks.ModuleVersion.IncludePrerelease' = @{Validate = 'boolean'}
        'Tasks.ModuleVersion.Remote'            = @{Validate = 'string'}
        'Tasks.ModuleVersion.Source'            = @{
            Validate = 'enum'
            Values   = @('PSGallery', 'GitTag')
        }
        'Tasks.ChangelogUpdated.EnforceWhen'    = $enforceWhenRule
        'Tasks.PesterIntegration.EnforceWhen'   = $enforceWhenRule
        'Tasks.PesterIntegration.StreamOutput'  = @{Validate = 'boolean'}
        'Tasks.PesterUnit.EnforceWhen'          = $enforceWhenRule
        'Tasks.PesterUnit.StreamOutput'         = @{Validate = 'boolean'}
        'Tasks.PSScriptAnalyzer.EnforceWhen'    = $enforceWhenRule
        'Tasks.PSScriptAnalyzer.Exclude'        = @{Validate = 'string-array'}
        'Tasks.PSScriptAnalyzer.IncludeTests'   = @{Validate = 'boolean'}
        'Tasks.Manifest.EnforceWhen'            = $enforceWhenRule
        'Tasks.PublicFunctions.EnforceWhen'     = $enforceWhenRule
        'Tasks.PublicFunctionPrefix.EnforceWhen' = $enforceWhenRule
        'Tasks.PublicFunctionPrefix.Exclusions' = @{Validate = 'string-array'}
        'Tasks.PublicFunctionPrefix.Prefix'     = @{Validate = 'string'; Nullable = $true}
        'Tasks.FunctionFiles.EnforceWhen'       = $enforceWhenRule
        'Tasks.FunctionFiles.Exclude'           = @{Validate = 'string-array'}
        'Tasks.Naming.EnforceWhen'              = $enforceWhenRule
        'Tasks.ToDo.EnforceWhen'                = $enforceWhenRule
        'Tasks.ToDo.Exclude'                    = @{Validate = 'string-array'}
        'Tasks.YAML.EnforceWhen'                = $enforceWhenRule
        'Tasks.YAML.Exclude'                    = @{Validate = 'string-array'}
    }
}
