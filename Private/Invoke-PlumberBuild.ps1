function Invoke-PlumberBuild {
    <#
        .SYNOPSIS
        Runs Invoke-Build for Invoke-Plumber.

        .DESCRIPTION
        Invokes the requested task against a build file and returns the
        Invoke-Build result object. A unique result variable is used so nested
        or mocked build calls do not clobber each other.

        .PARAMETER Task
        The Invoke-Build task names to run.

        .PARAMETER BuildFile
        The build script file to execute.

        .EXAMPLE
        Invoke-PlumberBuild -Task Validate -BuildFile ./Plumber.build.ps1

        Runs the Validate task and returns the Invoke-Build result object.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [string[]]
        $Task,

        [Parameter(Mandatory)]
        [string]
        $BuildFile
    )

    $invokeBuild = Get-Command Invoke-Build
    $resultVariable = "plumberBuildResult_$([guid]::NewGuid().ToString('N'))"
    $null = & $invokeBuild -Task $Task -File $BuildFile -Result $resultVariable
    Get-Variable -Name $resultVariable -ValueOnly
    Remove-Variable -Name $resultVariable -ErrorAction SilentlyContinue
}
