function Get-PlumberTaskHelp {
    <#
        .SYNOPSIS
        Gets parsed help metadata for a Plumber task file.

        .DESCRIPTION
        Reads a Plumber task documentation block and returns the fields needed
        to generate task documentation.

        .PARAMETER Path
        The task file path to inspect.

        .EXAMPLE
        Get-PlumberTaskHelp -Path ./Tasks/Content/YAML.ps1

        Returns parsed task documentation metadata for the YAML task.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $Path,
        [ref] $tokens,
        [ref] $parseErrors
    )
    if ($parseErrors) {
        throw "Failed to parse task help from $Path"
    }

    $taskCommand = $ast.Find(
        {
            param ($node)

            if ($node -isnot [System.Management.Automation.Language.CommandAst]) {
                return $false
            }

            $commandName = $node.GetCommandName()
            $commandName -eq 'Add-BuildTask' -or $commandName -eq 'task'
        },
        $true
    )
    if (-not $taskCommand) {
        throw "No Plumber task command found in $Path"
    }

    $taskName = [System.IO.Path]::GetFileNameWithoutExtension($Path)

    $comment = $tokens |
        Where-Object {
            $_.Kind -eq 'Comment' -and
            $_.Text -like '<#*#>' -and
            $_.Extent.EndOffset -le $taskCommand.Extent.StartOffset
        } |
            Select-Object -Last 1
    if (-not $comment) {
        throw "No Plumber task documentation block found in $Path"
    }

    $sections = ConvertFrom-PlumberTaskHelpComment -Text $comment.Text
    $includes = @()
    if ($sections.ContainsKey('INCLUDES')) {
        $includes = @(
            $sections.INCLUDES -split '\r?\n' |
                ForEach-Object {$_.Trim()} |
                    Where-Object {$_}
        )
    }

    [pscustomobject]@{
        Name          = $taskName
        Path          = $Path
        Synopsis      = Get-PlumberTaskHelpSection -Sections $sections -Name 'SYNOPSIS'
        Description   = Get-PlumberTaskHelpSection -Sections $sections -Name 'DESCRIPTION'
        Group         = Get-PlumberTaskHelpSection -Sections $sections -Name 'GROUP'
        Includes      = $includes
        Configuration = Get-PlumberTaskHelpSection -Sections $sections -Name 'CONFIGURATION'
        Run           = Get-PlumberTaskHelpSection -Sections $sections -Name 'RUN'
        Pass          = Get-PlumberTaskHelpSection -Sections $sections -Name 'PASS'
        Fail          = Get-PlumberTaskHelpSection -Sections $sections -Name 'FAIL'
        IsGroup       = $includes.Count -gt 0
    }
}
