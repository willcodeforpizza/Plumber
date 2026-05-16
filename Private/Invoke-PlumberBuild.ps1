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
    $invokeBuildCommand = if ($invokeBuild.CommandType -eq 'Alias') {
        $invokeBuild.Definition
    } else {
        $invokeBuild
    }
    $resultVariable = "plumberBuildResult_$([guid]::NewGuid().ToString('N'))"
    $runner = [scriptblock]::Create(@'
param (
    $InvokeBuildCommand,

    [string[]]
    $Task,

    [string]
    $BuildFile,

    [string]
    $ResultVariable,

    [bool]
    $RawOutput
)

if ($RawOutput) {
    & $InvokeBuildCommand -Task $Task -File $BuildFile -Result $ResultVariable |
        Out-Host
} else {
    $null = & $InvokeBuildCommand -Task $Task -File $BuildFile -Result $ResultVariable *> $null
}

Get-Variable -Name $ResultVariable -ValueOnly -ErrorAction SilentlyContinue
Remove-Variable -Name $ResultVariable -ErrorAction SilentlyContinue
'@)
    $streamVariableSplat = @{
        Name        = 'PlumberStreamPesterOutput'
        Scope       = 'Global'
        ErrorAction = 'SilentlyContinue'
    }
    $streamVariableExists = Get-Variable @streamVariableSplat
    $previousStreamPesterOutput = if ($streamVariableExists) {
        Get-Variable -Name PlumberStreamPesterOutput -Scope Global -ValueOnly
    }

    try {
        Set-Variable -Name PlumberStreamPesterOutput -Scope Global -Value ([bool]$RawOutput)

        $buildResult = & $runner $invokeBuildCommand $Task $BuildFile $resultVariable ([bool]$RawOutput)
    } finally {
        if (-not $streamVariableExists) {
            Remove-Variable -Name PlumberStreamPesterOutput -Scope Global -ErrorAction SilentlyContinue
        } else {
            Set-Variable -Name PlumberStreamPesterOutput -Scope Global -Value $previousStreamPesterOutput
        }
    }

    if (-not $buildResult) {
        throw 'Invoke-Build did not return a result object.'
    }

    $buildResult
}
