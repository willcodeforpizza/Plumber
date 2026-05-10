function Test-PlumberFunctionHelp {
    <#
        .SYNOPSIS
        Tests function help metadata for required sections.

        .DESCRIPTION
        Validates parsed function help metadata and returns messages for any
        missing required help sections.

        .PARAMETER Help
        The parsed help metadata to validate.

        .PARAMETER RequireFullHelp
        Require description, parameters and examples in addition to synopsis.

        .EXAMPLE
        Test-PlumberFunctionHelp -Help $help -RequireFullHelp

        Returns missing help section messages for a public function.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $Help,

        [switch]
        $RequireFullHelp
    )

    if (
        -not $Help.Synopsis -or
        $Help.Synopsis -eq $Help.Name
    ) {
        "$($Help.Name): Missing help synopsis"
    }

    if (-not $RequireFullHelp) {
        return
    }

    if (-not $Help.Description) {
        "$($Help.Name): Missing help description"
    }

    if ($Help.HasParameter -and -not $Help.Parameters) {
        "$($Help.Name): Missing help parameter documentation"
    }

    if (-not $Help.Examples) {
        "$($Help.Name): Missing help example"
    }
}
