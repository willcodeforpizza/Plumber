function Get-PlumberTaskLoader {
    <#
        .SYNOPSIS
        Gets the Plumber task loader script path

        .DESCRIPTION
        Returns the path to Plumber's task loader script. Build files dot-source
        this path so Plumber tasks are registered in the active Invoke-Build
        scope.

        .EXAMPLE
        . (Get-PlumberTaskLoader) -Config @{
            ModuleManifest = 'MyModule.psd1'
        }

        Loads Plumber tasks into the current Invoke-Build script with module
        configuration.

        .EXAMPLE
        Get-PlumberTaskLoader

        Returns the full path to Tasks/TaskLoader.ps1.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    $moduleRoot = if ($script:moduleRoot) {
        $script:moduleRoot
    } else {
        Split-Path $PSScriptRoot -Parent
    }

    Join-Path $moduleRoot 'Tasks/TaskLoader.ps1'
}
