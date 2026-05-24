function Import-PlumberTask {
    <#
        .SYNOPSIS
        Creates metadata for a Plumber task import.

        .DESCRIPTION
        Returns task import metadata including the task's EnforceWhen policy and
        whether it should run in the current context. TaskLoader.ps1 uses this
        metadata to dot-source task files or register explicit skip tasks in the
        active Invoke-Build scope.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $TaskRoot,

        [string]
        $Parent,

        [ValidateSet('Always', 'OnRelease', 'Never')]
        [string]
        $EnforceWhen = 'Always'
    )

    [pscustomobject]@{
        Name        = $Name
        FullName    = Join-Path $TaskRoot $Path
        Parent      = $Parent
        EnforceWhen = $EnforceWhen
        ShouldRun   = Test-PlumberTaskEnabled -Name $Name -EnforceWhen $EnforceWhen
    }
}
