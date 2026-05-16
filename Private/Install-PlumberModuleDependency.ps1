function Install-PlumberModuleDependency {
    <#
        .SYNOPSIS
        Installs a PowerShell module dependency for Plumber.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string]
        $RequiredVersion
    )

    $installSplat = @{
        Name               = $Name
        RequiredVersion    = $RequiredVersion
        Scope              = 'CurrentUser'
        Force              = $true
        SkipPublisherCheck = $true
        ErrorAction        = 'Stop'
    }
    Install-Module @installSplat
}
