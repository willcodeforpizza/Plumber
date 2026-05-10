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

        .PARAMETER RawOutput
        Streams Invoke-Build output before returning the result object.

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
        $BuildFile,

        [switch]
        $RawOutput
    )

    $invokeBuild = Get-Command Invoke-Build
    $resultVariable = "plumberBuildResult_$([guid]::NewGuid().ToString('N'))"

    if ($RawOutput) {
        & $invokeBuild -Task $Task -File $BuildFile -Result $resultVariable |
            Out-Host
    } else {
        $null = & $invokeBuild -Task $Task -File $BuildFile -Result $resultVariable *> $null
    }

    Get-Variable -Name $resultVariable -ValueOnly
    Remove-Variable -Name $resultVariable -ErrorAction SilentlyContinue
}
