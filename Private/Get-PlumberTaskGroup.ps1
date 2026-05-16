function Get-PlumberTaskGroup {
    <#
        .SYNOPSIS
        Gets Plumber's built-in validation task groups.
    #>
    [CmdletBinding()]
    [OutputType([System.Array])]
    param ()

    @(
        @{
            Parent   = 'CodeQuality'
            Children = @(
                'PSScriptAnalyzer',
                'Backticks',
                'LineLength',
                'PathSeparator',
                'PesterUnit',
                'PesterIntegration',
                'CodeCoverage'
            )
        }
        @{
            Parent   = 'ReleaseHygiene'
            Children = @('ModuleVersion', 'ChangelogUpdated')
        }
        @{
            Parent   = 'Content'
            Children = @('JSON', 'JSONSchema', 'YAML')
        }
        @{
            Parent   = 'ModuleConventions'
            Children = @(
                'Manifest',
                'PublicFunctions',
                'PublicFunctionPrefix',
                'FunctionFiles',
                'Naming',
                'ToDo',
                'Help'
            )
        }
    )
}
