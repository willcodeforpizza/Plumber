function Initialize-PlumberTaskGraph {
    <#
        .SYNOPSIS
        Creates the task job graph used by Plumber's task loader.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()

    @{
        CodeQuality       = @()
        ReleaseHygiene    = @()
        Content           = @()
        ModuleConventions = @()
        Local             = @()
        Validate          = @('SetVariables')
    }
}
