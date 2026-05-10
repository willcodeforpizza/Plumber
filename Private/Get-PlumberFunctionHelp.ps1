function Get-PlumberFunctionHelp {
    <#
        .SYNOPSIS
        Gets parsed help metadata for a PowerShell function file.

        .DESCRIPTION
        Reads comment-based help from a function file and returns the fields
        needed by the Help validation task.

        .PARAMETER Path
        The function file path to inspect.

        .EXAMPLE
        Get-PlumberFunctionHelp -Path ./Public/Invoke-Thing.ps1

        Returns parsed comment-based help metadata for Invoke-Thing.
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
        throw "Failed to parse function help from $Path"
    }

    $function = $ast.Find(
        {
            param ($node)

            $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
        },
        $true
    )
    $help = $function.GetHelpContent()
    $synopsis = if ($help.Synopsis) {
        $help.Synopsis.Trim()
    }
    $description = if ($help.Description) {
        $help.Description.Trim()
    }
    $parameters = if ($help.Parameters) {
        @($help.Parameters.Keys)
    } else {
        @()
    }
    $examples = if ($help.Examples) {
        @($help.Examples)
    } else {
        @()
    }

    [pscustomobject]@{
        Name         = $function.Name
        Path         = $Path
        Synopsis     = $synopsis
        Description  = $description
        Parameters   = $parameters
        Examples     = $examples
        HasParameter = [bool] $function.Body.ParamBlock.Parameters
    }
}
